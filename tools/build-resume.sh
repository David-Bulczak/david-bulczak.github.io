#!/usr/bin/env bash
#
# Rebuilds assets/David-Bulczak-Resume.pdf from the LaTeX CV sources.
#
# The published PDF is the game-dev CV variant (resume_cv.tex) with the postal
# address and mobile number removed, because the site is public. This script is
# the only supported way to refresh it: it redacts, compiles, and then verifies
# that the redacted values really are absent from the finished PDF.
#
# Usage:
#   tools/build-resume.sh [path-to-job-application-repo]
#
# Defaults to $RESUME_SRC, then ~/Documents/Job/job-application.
# The source repo is never modified; redaction happens on a throwaway copy.

set -euo pipefail

SRC="${1:-${RESUME_SRC:-$HOME/Documents/Job/job-application}}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO_ROOT/assets/David-Bulczak-Resume.pdf"
TEX_MAIN="resume_cv.tex"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

command -v xelatex   >/dev/null || die "xelatex not found (awesome-cv requires XeLaTeX)"
command -v pdftotext >/dev/null || die "pdftotext not found (needed to verify redaction)"
[ -d "$SRC" ]                   || die "source dir not found: $SRC"
[ -f "$SRC/$TEX_MAIN" ]         || die "$TEX_MAIN not found in $SRC"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cp -r "$SRC/$TEX_MAIN" "$SRC/awesome-cv.cls" "$SRC/fontawesome.sty" \
      "$SRC/fonts" "$SRC/cv-sections" "$WORK/"
cd "$WORK"

# --- Capture what we are about to redact, so we can verify it later -----------
addr="$(sed -n 's/^[[:space:]]*\\address{\(.*\)}[[:space:]]*$/\1/p' "$TEX_MAIN" | head -1)"
mob="$(sed -n 's/^[[:space:]]*\\mobile{\(.*\)}[[:space:]]*$/\1/p'  "$TEX_MAIN" | head -1)"

[ -n "$addr" ] || die "no active \\address{} line in $TEX_MAIN — template changed, update this script"
[ -n "$mob"  ] || die "no active \\mobile{} line in $TEX_MAIN — template changed, update this script"

# --- Redact ------------------------------------------------------------------
sed -i -E '/^[[:space:]]*\\(address|mobile)\{/ s/^/% /' "$TEX_MAIN"

grep -qE '^[[:space:]]*\\(address|mobile)\{' "$TEX_MAIN" \
  && die "redaction failed: an uncommented \\address/\\mobile line remains"

# --- Compile (twice, so page numbers in the footer settle) -------------------
for _ in 1 2; do
  xelatex -interaction=nonstopmode -halt-on-error "$TEX_MAIN" >/dev/null \
    || { xelatex -interaction=nonstopmode "$TEX_MAIN" | tail -30; die "xelatex failed"; }
done
[ -f resume_cv.pdf ] || die "xelatex produced no PDF"

# --- Verify the redacted values are really gone ------------------------------
# Only tokens unique to the address/phone are checked. Words that legitimately
# appear elsewhere in the CV (e.g. "Germany" in job locations) are skipped, by
# testing each token against the source with those two lines stripped out.
pdftotext resume_cv.pdf - > extracted.txt
grep -vE '^[[:space:]]*% *\\(address|mobile)\{' "$TEX_MAIN" > rest.tex
cat cv-sections/*.tex >> rest.tex

leaked=0
while read -r tok; do
  [ -n "$tok" ] || continue
  grep -qiF -- "$tok" rest.tex && continue          # appears elsewhere legitimately
  if grep -qiF -- "$tok" extracted.txt; then
    printf 'error: %s still present in the built PDF\n' "$tok" >&2
    leaked=1
  fi
done < <(printf '%s %s' "$addr" "$mob" | tr -cs '[:alnum:]' '\n' | awk 'length($0) >= 4' | sort -u)

[ "$leaked" -eq 0 ] || die "redaction verification failed — PDF not published"

pages="$(pdfinfo resume_cv.pdf 2>/dev/null | awk '/^Pages:/ {print $2}')"

cp resume_cv.pdf "$OUT"
printf 'Wrote %s (%s bytes%s)\n' \
  "${OUT#"$REPO_ROOT"/}" "$(stat -c%s "$OUT")" "${pages:+, $pages pages}"
printf 'Redacted: %s | %s\n' "$addr" "$mob"
printf 'Remember to commit the updated PDF.\n'

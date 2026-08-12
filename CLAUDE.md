# david-bulczak.github.io

Personal portfolio / resume site. Static, served by GitHub Pages from `main`
(no build step, no Jekyll config — files are published as-is).

Based on the BootstrapMade "Personal" template; vendor libraries live in
`assets/vendor/` and should not be hand-edited. Site styles are in
`assets/css/style.css`; the accent colour is `#dc3522`.

## The resume PDF is generated — never edit or copy it by hand

`assets/David-Bulczak-Resume.pdf` is **derived** from the LaTeX CV in
`~/Documents/Job/job-application` (`resume_cv.tex`, the game-dev variant). It is
not the same file as `resume_cv.pdf` in that repo: the site copy has the postal
address and mobile number stripped, because this site is public and anything
published here is crawled and archived permanently.

To refresh it after the CV changes:

```sh
tools/build-resume.sh                 # defaults to ~/Documents/Job/job-application
tools/build-resume.sh /path/to/cv     # or point it somewhere else
```

The script copies the LaTeX project to a temp dir (the CV repo is never
modified), comments out `\address` and `\mobile`, compiles with XeLaTeX, and
then verifies the redacted values are absent from the finished PDF before
writing it into `assets/`. It fails closed: if the CV template changes shape so
the redaction no longer matches, the build aborts rather than publishing.

Requires `xelatex` and `pdftotext`.

Note that each build embeds a fresh timestamp, so the PDF bytes always differ
even when the content is unchanged. Check with
`pdftotext` before committing a churn-only diff.

## Clean section URLs

`/resume`, `/about`, `/portfolio` and `/contact` are directories each holding a
small `index.html` that redirects to the matching anchor on the main page
(`/#resume` etc.). GitHub Pages is static-only and cannot rewrite URLs
server-side, so this redirect hop is what makes those links work; the address
bar ends up showing the anchor form. They are `noindex` with a canonical
pointing at the main page.

`assets/js/section-url.js` then keeps the address bar in step as you click
around: the template is a section-swap layout whose nav handler calls
`preventDefault()` and never touches `location`, so without this the URL would
stay frozen at whatever the page was opened with. It rewrites `/#resume` to
`/resume` on load and `pushState`s the clean path on each nav click, with
`popstate` replaying the matching link so back/forward work.

It **must stay after `main.js`** in `index.html` — `main.js` reads
`location.hash` on `load` to pick the initial section, so the hash has to
survive until then.

If a new nav section is added to `index.html`, add a matching directory to keep
the set consistent, and add its id to `SECTIONS` in `section-url.js`.

## Content sources

Resume and skills content mirrors the LaTeX CV in
`~/Documents/Job/job-application/cv-sections/`. The site uses the **game-dev**
framing (`experience.tex`, `skills.tex`), not the general-SWE variant. When the
CV changes, update the Resume and Skills sections of `index.html` to match, and
rebuild the PDF.

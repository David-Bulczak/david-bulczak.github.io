# david-bulczak.github.io

Personal portfolio and resume site, served by GitHub Pages from `main` at
<https://david-bulczak.github.io>.

Static site — no build step. Pushing to `main` publishes; the CDN caches for
about 10 minutes.

## Resume PDF

`assets/David-Bulczak-Resume.pdf` is generated from the LaTeX CV, with the
postal address and mobile number removed for public publication. Regenerate it
after changing the CV:

```sh
tools/build-resume.sh
```

See [CLAUDE.md](CLAUDE.md) for details and the rest of the repo conventions.

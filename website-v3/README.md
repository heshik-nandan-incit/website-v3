# website-v3

This folder contains a rebuilt static version of the INCIT website generated from the scraped HTML under `../pages`, using canonical URLs and internal navigation patterns as the source of truth for hierarchy.

## Rules followed

- `prompt.md` is treated as the instruction baseline and is not modified.
- Output paths are reconstructed from canonical URLs, not from the scraped sitemap folder layout.
- Site hierarchy is reconstructed into `website-v3/site` from canonical URLs.
- Remote asset URLs are kept intact because the reference folder does not include a local asset mirror.
- Absolute `https://incit.org/...` links are left unchanged in this pass and called out in `reports/validation-report.md`.

## Regenerate

Run from the repository root:

```bash
bash website-v3/tools/rebuild.sh
```

## Serve Locally

Serve `website-v3/site` as the web root. This is required because the HTML uses root-relative paths like `/who-we-are/`.

```bash
bash website-v3/tools/serve.sh
```

Or use `npm` from `website-v3`:

```bash
cd website-v3
npm run serve
```

If you serve `website-v3` instead of `website-v3/site`, links such as `/who-we-are/` will resolve to `website-v3/who-we-are/` and return 404 because the generated pages live under `website-v3/site/...`.

## Reports

- `reports/site-map.json`: generated route to source-file mapping
- `reports/build-summary.json`: summary, duplicates, unresolved links, backend dependencies
- `reports/validation-report.md`: human-readable validation notes
- `reports/nav-audit.json`: navbar link verification report
- `reports/shared-components.json`: shared header/footer component usage report
- `reports/shared-card-modal.json`: shared card-modal asset usage report

## Shared Components

These files are the editable shared sources used across the generated pages:

- `components/header.html`
- `components/footer.html`
- `assets/incit-card-modal.css`
- `assets/incit-card-modal.js`

The build injects those shared blocks into every page that contains the matching header/footer wrappers, so you can update the common navigation or footer in one place and then rerun:

```bash
cd website-v3
npm run build
```

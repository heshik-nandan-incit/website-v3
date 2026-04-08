# Website V3 Validation Report

Generated: 2026-04-08T02:37:35Z

## Summary

- Source HTML files scanned: 329
- Pages generated in `website-v3/site`: 328
- Duplicate canonical routes detected: 1
- Reconstruction basis: canonical URLs extracted from source pages
- Output strategy: clone-copied source HTML placed into reconstructed folder hierarchy
- Navbar audit report: `reports/nav-audit.json`
- Shared component report: `reports/shared-components.json`
- Shared card-modal report: `reports/shared-card-modal.json`

## Notes

- `prompt.md` was preserved and not modified.
- The source corpus is approximately 8.2 GB, with several pages tens to hundreds of MB each.
- Because of source size, this build reconstructs hierarchy without full HTML rewriting.
- Root-relative links such as `/what-we-do/...` resolve against the rebuilt hierarchy when hosted at the site root.
- Absolute `https://incit.org/...` links remain unchanged and should be normalized in a later pass if deployment will not use the original domain.
- Remote assets remain unchanged because no local asset mirror exists in the provided reference folder.
- Missing navbar landing pages were rebuilt as minimal section indexes or redirect aliases derived from available routes.
- Header and footer are centralized through `components/header.html` and `components/footer.html`; the build injects those shared blocks into all matching pages.
- The reusable `incit-card` popup system now uses shared assets in `assets/incit-card-modal.css` and `assets/incit-card-modal.js`, while each page keeps its own content.

## Duplicate Canonicals

- /contact-us/ :: chosen /Users/heshiknandan/Desktop/workspace/incit-website/pages/page-sitemap/contact-us.html (score 170) :: alternate /Users/heshiknandan/Desktop/workspace/incit-website/pages/page-sitemap/frequently-asked-questions.html (score 70)

#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SITE_ROOT = ROOT / "site"
REPORTS_ROOT = ROOT / "reports"

CSS_LINK = '<link rel="stylesheet" href="/assets/incit-card-modal.css" data-incit-card-modal-shared="true"/>'
JS_SCRIPT = '<script defer src="/assets/incit-card-modal.js" data-incit-card-modal-shared="true"></script>'

SCRIPT_BLOCK_PATTERN = re.compile(r"<script\b[^>]*>[\s\S]*?</script>", re.IGNORECASE)


def strip_legacy_modal_scripts(text: str) -> tuple[str, int]:
    removed = 0

    def replacer(match: re.Match[str]) -> str:
        nonlocal removed
        block = match.group(0)
        if (
            "const swiper = new Swiper" in block
            and "openModal(" in block
            and "incit-card-backdrop" in block
        ):
            removed += 1
            return ""
        return block

    return SCRIPT_BLOCK_PATTERN.sub(replacer, text), removed


def main() -> None:
    stats = {
        "pagesScanned": 0,
        "pagesWithCardModal": 0,
        "pagesLinkedSharedCss": 0,
        "pagesLinkedSharedJs": 0,
        "inlineModalScriptsRemoved": 0,
    }

    for file in SITE_ROOT.rglob("*.html"):
        stats["pagesScanned"] += 1
        text = file.read_text(encoding="utf-8", errors="ignore")

        if "elementor-widget-card-siri-slider" not in text:
            continue

        stats["pagesWithCardModal"] += 1
        changed = False

        if 'data-incit-card-modal-shared="true"' not in text:
            head_close = text.rfind("</head>")
            if head_close != -1:
                text = text[:head_close] + CSS_LINK + "\n" + text[head_close:]
                stats["pagesLinkedSharedCss"] += 1
                changed = True

        if JS_SCRIPT not in text:
            body_close = text.rfind("</body>")
            if body_close != -1:
                text = text[:body_close] + JS_SCRIPT + "\n" + text[body_close:]
                stats["pagesLinkedSharedJs"] += 1
                changed = True

        text, removed = strip_legacy_modal_scripts(text)
        if removed:
            stats["inlineModalScriptsRemoved"] += removed
            changed = True

        if changed:
            file.write_text(text, encoding="utf-8")

    report = {
        "sharedComponents": [
            {"name": "incit-card-modal-css", "path": "assets/incit-card-modal.css"},
            {"name": "incit-card-modal-js", "path": "assets/incit-card-modal.js"},
        ],
        "stats": stats,
    }
    (REPORTS_ROOT / "shared-card-modal.json").write_text(json.dumps(report, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()

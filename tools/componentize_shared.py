#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SITE_ROOT = ROOT / "site"
COMPONENTS_ROOT = ROOT / "components"
REPORTS_ROOT = ROOT / "reports"

HEADER_START = '<header class="elementor elementor-39255 elementor-location-header"'
HEADER_END = "</header>"
FOOTER_START = '<footer class="elementor elementor-34432 elementor-location-footer"'
FOOTER_END = "</footer>"


def extract_block(text: str, start_marker: str, end_marker: str) -> str | None:
    start = text.find(start_marker)
    if start == -1:
        return None
    end = text.find(end_marker, start)
    if end == -1:
        return None
    return text[start : end + len(end_marker)]


def ensure_component(component_path: Path, content: str) -> None:
    component_path.parent.mkdir(parents=True, exist_ok=True)
    if not component_path.exists():
        component_path.write_text(content, encoding="utf-8")


def replace_block(text: str, start_marker: str, end_marker: str, replacement: str) -> tuple[str, bool]:
    block = extract_block(text, start_marker, end_marker)
    if block is None:
        return text, False
    if block == replacement:
        return text, False
    return text.replace(block, replacement, 1), True


def main() -> None:
    seed_page = SITE_ROOT / "index.html"
    seed_text = seed_page.read_text(encoding="utf-8", errors="ignore")

    header_seed = extract_block(seed_text, HEADER_START, HEADER_END)
    footer_seed = extract_block(seed_text, FOOTER_START, FOOTER_END)
    if header_seed is None or footer_seed is None:
      raise SystemExit("Could not locate header/footer blocks in seed page")

    header_component = COMPONENTS_ROOT / "header.html"
    footer_component = COMPONENTS_ROOT / "footer.html"

    ensure_component(header_component, header_seed)
    ensure_component(footer_component, footer_seed)

    header_html = header_component.read_text(encoding="utf-8", errors="ignore")
    footer_html = footer_component.read_text(encoding="utf-8", errors="ignore")

    stats = {
        "pagesScanned": 0,
        "headerPagesUpdated": 0,
        "footerPagesUpdated": 0,
        "pagesWithSharedHeader": 0,
        "pagesWithSharedFooter": 0,
    }

    for file in SITE_ROOT.rglob("*.html"):
        stats["pagesScanned"] += 1
        text = file.read_text(encoding="utf-8", errors="ignore")

        new_text, header_changed = replace_block(text, HEADER_START, HEADER_END, header_html)
        if extract_block(new_text, HEADER_START, HEADER_END) == header_html:
            stats["pagesWithSharedHeader"] += 1

        newer_text, footer_changed = replace_block(new_text, FOOTER_START, FOOTER_END, footer_html)
        if extract_block(newer_text, FOOTER_START, FOOTER_END) == footer_html:
            stats["pagesWithSharedFooter"] += 1

        if header_changed:
            stats["headerPagesUpdated"] += 1
        if footer_changed:
            stats["footerPagesUpdated"] += 1

        if header_changed or footer_changed:
            file.write_text(newer_text, encoding="utf-8")

    report = {
        "sharedComponents": [
            {"name": "header", "path": "components/header.html"},
            {"name": "footer", "path": "components/footer.html"},
        ],
        "stats": stats,
    }
    (REPORTS_ROOT / "shared-components.json").write_text(json.dumps(report, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()

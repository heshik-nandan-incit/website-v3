#!/usr/bin/env python3
import json
import os
import re
from pathlib import Path
from urllib.parse import urlparse

site_root = Path(__file__).resolve().parents[1] / "site"
base_path = (os.environ.get("BASE_PATH", "") or "").strip()
if base_path:
    base_path = "/" + base_path.strip("/")
class_pattern = re.compile(
    r'<a[^>]+class="[^"]*(?:nav-dropdown__item__sub-link|mobile-second-title-link-wrapper|footer__link)[^"]*"[^>]+href="([^"]+)"',
    re.I,
)

def classify_href(href: str):
    if href.startswith(("mailto:", "tel:", "#")):
        return {"status": "external", "target": href}

    parsed = urlparse(href)
    if parsed.scheme in {"http", "https"}:
        if parsed.netloc in {"incit.org", "www.incit.org"}:
            route = strip_base_path(parsed.path or "/")
            target = route_to_file(route)
            return {"status": "ok" if target.exists() else "broken", "target": str(target.relative_to(site_root))}
        return {"status": "external", "target": href}

    route = strip_base_path(parsed.path or "/")
    target = route_to_file(route)
    return {"status": "ok" if target.exists() else "broken", "target": str(target.relative_to(site_root))}


def route_to_file(route: str) -> Path:
    normalized = route if route.endswith("/") else f"{route}/"
    clean = normalized.lstrip("/")
    if not clean:
        return site_root / "index.html"
    return site_root / clean / "index.html"


def strip_base_path(route: str) -> str:
    if base_path and route.startswith(f"{base_path}/"):
        route = route[len(base_path):]
    elif base_path and route == base_path:
        route = "/"
    return route or "/"


pages_scanned = 0
href_usage = {}
broken = []

for file in site_root.rglob("index.html"):
    pages_scanned += 1
    try:
        text = file.read_text(errors="ignore")
    except Exception:
        continue

    seen_here = set(class_pattern.findall(text))
    for href in seen_here:
        href_usage[href] = href_usage.get(href, 0) + 1
        verdict = classify_href(href)
        if verdict["status"] == "broken":
            broken.append({
                "page": str(file.relative_to(site_root)),
                "href": href,
                "target": verdict["target"],
            })

summary = {
    "pagesScanned": pages_scanned,
    "uniqueNavLinks": len(href_usage),
    "brokenNavLinks": len(broken),
    "links": [
        {"href": href, "pages": href_usage[href], **classify_href(href)}
        for href in sorted(href_usage)
    ],
    "brokenDetails": broken,
}

print(json.dumps(summary, indent=2))

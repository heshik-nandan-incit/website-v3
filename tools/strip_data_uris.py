#!/usr/bin/env python3
import re
from pathlib import Path

site_root = Path(__file__).resolve().parents[1] / "site"

quoted_attr = re.compile(r'([A-Za-z0-9:-]+)=([\'"])(.*?)\2', re.I | re.S)
css_data_uri = re.compile(r"url\((['\"]?)data:image/.*?\1\)", re.I)


def sanitize_attr(match: re.Match[str]) -> str:
    name, quote, value = match.groups()
    lowered = value.lower()
    if ("data:image" in lowered or "base64," in lowered) and len(value) > 2048:
        return f"{name}={quote}{quote}"
    return match.group(0)


for file_path in site_root.rglob("index.html"):
    text = file_path.read_text(errors="ignore")
    updated = quoted_attr.sub(sanitize_attr, text)
    updated = css_data_uri.sub("url()", updated)
    if updated != text:
        file_path.write_text(updated)

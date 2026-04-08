#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_DIR="$ROOT_DIR/site"
PORT="${1:-8000}"

cd "$SITE_DIR"
exec python3 -m http.server "$PORT"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/pages"
OUTPUT_DIR="$ROOT_DIR"
SITE_DIR="$OUTPUT_DIR/site"
REPORTS_DIR="$OUTPUT_DIR/reports"
TMP_DIR="$OUTPUT_DIR/.tmp"
BASE_PATH="${BASE_PATH:-}"

mkdir -p "$SITE_DIR" "$REPORTS_DIR" "$TMP_DIR"

MANIFEST_ALL="$TMP_DIR/manifest-all.tsv"
MANIFEST_SORTED="$TMP_DIR/manifest-sorted.tsv"
MANIFEST_CHOSEN="$TMP_DIR/manifest-chosen.tsv"
DUPLICATES_TSV="$TMP_DIR/duplicates.tsv"

: > "$MANIFEST_ALL"

if [[ -n "$BASE_PATH" ]]; then
  BASE_PATH="/${BASE_PATH#/}"
  BASE_PATH="${BASE_PATH%/}"
  [[ "$BASE_PATH" == "/" ]] && BASE_PATH=""
fi

with_base_path() {
  local route="$1"

  if [[ -z "$BASE_PATH" || "$route" != /* ]]; then
    printf '%s' "$route"
    return
  fi

  if [[ "$route" == "/" ]]; then
    printf '%s/' "$BASE_PATH"
    return
  fi

  printf '%s%s' "$BASE_PATH" "$route"
}

write_redirect_page() {
  local route="$1"
  local destination="$2"
  local resolved_destination
  local target

  resolved_destination="$(with_base_path "$destination")"

  if [[ "$route" == "/" ]]; then
    target="$SITE_DIR/index.html"
  else
    target="$SITE_DIR/${route#/}"
    target="${target%/}/index.html"
  fi

  mkdir -p "$(dirname "$target")"
  cat > "$target" <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="0; url=$resolved_destination">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Redirecting</title>
  <script>window.location.replace("$resolved_destination");</script>
</head>
<body>
  <p>Redirecting to <a href="$resolved_destination">$resolved_destination</a>...</p>
</body>
</html>
EOF
}

write_section_index_page() {
  local route="$1"
  local title="$2"
  local target

  if [[ "$route" == "/" ]]; then
    target="$SITE_DIR/index.html"
  else
    target="$SITE_DIR/${route#/}"
    target="${target%/}/index.html"
  fi

  mkdir -p "$(dirname "$target")"
  {
    echo '<!doctype html>'
    echo '<html lang="en">'
    echo '<head>'
    echo '  <meta charset="utf-8">'
    echo '  <meta name="viewport" content="width=device-width, initial-scale=1">'
    echo "  <title>$title</title>"
    echo '  <style>'
    echo '    body{font-family:Arial,sans-serif;max-width:960px;margin:40px auto;padding:0 20px;line-height:1.5;color:#111}'
    echo '    h1{margin-bottom:16px}'
    echo '    ul{padding-left:20px}'
    echo '    li{margin:8px 0}'
    echo '    a{color:#005fcc;text-decoration:none}'
    echo '    a:hover{text-decoration:underline}'
    echo '  </style>'
    echo '</head>'
    echo '<body>'
    echo "  <h1>$title</h1>"
    echo '  <ul>'
    awk -F $'\t' -v prefix="$route" '
      $1 ~ ("^" prefix) && $1 != prefix {
        print $1
      }
    ' "$MANIFEST_CHOSEN" | sort | while IFS= read -r child; do
      [[ -z "$child" ]] && continue
      printf '    <li><a href="%s">%s</a></li>\n' "$(with_base_path "$child")" "$child"
    done
    echo '  </ul>'
    echo '</body>'
    echo '</html>'
  } > "$target"
}

normalize_local_nav_links() {
  find "$SITE_DIR" -type f -name 'index.html' -print0 | while IFS= read -r -d '' file; do
    INCIT_BASE_PATH="$BASE_PATH" perl -0pi -e '
      my $base = $ENV{INCIT_BASE_PATH} // q{};
      s/href="https:\/\/incit\.org\/who-we-support\/technology-solution-providers\/"/href="${base}\/who-we-support\/technology-solution-providers\/"/g;
    ' "$file"
  done
}

apply_base_path() {
  [[ -z "$BASE_PATH" ]] && return

  find "$SITE_DIR" -type f -name 'index.html' -print0 | while IFS= read -r -d '' file; do
    python3 - "$file" "$BASE_PATH" <<'PY'
import re
import sys
from pathlib import Path

file_path = Path(sys.argv[1])
base_path = sys.argv[2].rstrip("/")
text = file_path.read_text(errors="ignore")

text = re.sub(
    r'((?:href|src|action)=["\'])/(?!/)',
    lambda m: f"{m.group(1)}{base_path}/",
    text,
)

file_path.write_text(text)
PY
  done
}

normalize_route() {
  perl -e '
    my $route = shift // "/";
    $route =~ s/\r//g;
    $route =~ s/\?.*$//;
    $route =~ s/#.*$//;
    $route = "/$route" unless $route =~ m{^/};
    $route =~ s{/index\.html$}{/}i;
    $route =~ s{/+}{/}g;
    $route .= "/" if $route ne "/" && $route !~ m{/$};
    print $route;
  ' "$1"
}

extract_route_from_file() {
  local file="$1"
  local canonical route relative

  canonical="$(perl -ne 'if ($. <= 80 && /<link href="(https?:\/\/(?:www\.)?incit\.org[^"]*)" rel="canonical"\s*\/?>/i) { print $1; exit } exit if $. > 80' "$file")"

  if [[ -n "$canonical" ]]; then
    route="$(perl -e '
      my $url = shift // "";
      $url =~ s{^https?://(?:www\.)?incit\.org}{};
      $url =~ s/\?.*$//;
      $url =~ s/#.*$//;
      print $url || "/";
    ' "$canonical")"
    normalize_route "$route"
    return
  fi

  relative="${file#"$SOURCE_DIR"/}"
  relative="${relative#page-sitemap/}"
  relative="${relative#post-sitemap1/}"
  relative="${relative#post-sitemap2/}"
  relative="${relative#getit-sitemap/}"
  relative="${relative#experts-sitemap/}"
  relative="${relative%.html}"
  normalize_route "/$relative/"
}

score_entry() {
  local route="$1"
  local folder="$2"
  local source_name="$3"
  local canonical="$4"
  local last_segment score

  last_segment="$(printf '%s' "$route" | awk -F/ '
    {
      n = split($0, parts, "/");
      for (i = n; i >= 1; --i) {
        if (parts[i] != "") { print parts[i]; exit }
      }
      print "index";
    }'
  )"

  score=0
  [[ -n "$canonical" ]] && score=$((score + 50))
  [[ "$source_name" == "$last_segment" ]] && score=$((score + 100))
  [[ "$source_name" == "incit.org" && "$route" == "/" ]] && score=$((score + 100))

  case "$folder" in
    page-sitemap) score=$((score + 20)) ;;
    post-sitemap1|post-sitemap2) score=$((score + 10)) ;;
  esac

  printf '%s' "$score"
}

while IFS= read -r -d '' file; do
  folder="$(dirname "${file#"$SOURCE_DIR"/}")"
  folder="${folder%%/*}"
  source_name="$(basename "$file" .html)"
  canonical="$(perl -ne 'if ($. <= 80 && /<link href="(https?:\/\/(?:www\.)?incit\.org[^"]*)" rel="canonical"\s*\/?>/i) { print $1; exit } exit if $. > 80' "$file")"
  route="$(extract_route_from_file "$file")"
  score="$(score_entry "$route" "$folder" "$source_name" "$canonical")"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$route" "$score" "$file" "$folder" "$source_name" "$canonical" >> "$MANIFEST_ALL"
done < <(find "$SOURCE_DIR" -type f -name '*.html' -print0)

sort -t $'\t' -k1,1 -k2,2nr -k3,3 "$MANIFEST_ALL" > "$MANIFEST_SORTED"

awk -F '\t' '
  !seen[$1]++ { print > chosen }
  seen[$1] > 1 { print > dups }
' chosen="$MANIFEST_CHOSEN" dups="$DUPLICATES_TSV" "$MANIFEST_SORTED"

while IFS=$'\t' read -r route score source_file folder source_name canonical; do
  if [[ "$route" == "/" ]]; then
    target="$SITE_DIR/index.html"
  else
    clean_route="${route#/}"
    clean_route="${clean_route%/}"
    target="$SITE_DIR/$clean_route/index.html"
  fi

  mkdir -p "$(dirname "$target")"
  rm -f "$target"
  cp -c "$source_file" "$target"
done < "$MANIFEST_CHOSEN"

write_section_index_page "/newsroom/" "Newsroom"
write_section_index_page "/thought-leadership/" "Thought Leadership"
write_section_index_page "/case-studies/" "Case Studies"

write_redirect_page "/what-we-do/aimri/certified-assessor/" "/certified-assessor/"
write_redirect_page "/what-we-do/siri/certified-assessor/" "/certified-assessor/"
write_redirect_page "/what-we-do/siri/assessment/" "/what-we-do/assessment-homepage/"
write_redirect_page "/what-we-do/operi/consultants/" "/who-we-support/consultants/"

normalize_local_nav_links

python3 "$OUTPUT_DIR/tools/componentize_shared.py"
python3 "$OUTPUT_DIR/tools/componentize_card_modal.py"
python3 "$OUTPUT_DIR/tools/strip_data_uris.py"
apply_base_path
touch "$SITE_DIR/.nojekyll"
BASE_PATH="$BASE_PATH" python3 "$OUTPUT_DIR/tools/check_nav.py" > "$REPORTS_DIR/nav-audit.json"

{
  echo "# Website V3 Validation Report"
  echo
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo
  echo "## Summary"
  echo
  echo "- Source HTML files scanned: $(wc -l < "$MANIFEST_ALL" | tr -d ' ')"
  echo "- Pages generated in \`site\`: $(wc -l < "$MANIFEST_CHOSEN" | tr -d ' ')"
  echo "- Duplicate canonical routes detected: $(wc -l < "$DUPLICATES_TSV" | tr -d ' ')"
  echo "- Reconstruction basis: canonical URLs extracted from source pages"
  echo "- Output strategy: clone-copied source HTML placed into reconstructed folder hierarchy"
  echo "- Navbar audit report: \`reports/nav-audit.json\`"
  echo "- Shared component report: \`reports/shared-components.json\`"
  echo "- Shared card-modal report: \`reports/shared-card-modal.json\`"
  echo
  echo "## Notes"
  echo
  echo "- \`prompt.md\` was preserved and not modified."
  echo "- The source corpus is approximately 8.2 GB, with several pages tens to hundreds of MB each."
  echo "- Because of source size, this build reconstructs hierarchy without full HTML rewriting."
  if [[ -n "$BASE_PATH" ]]; then
    echo "- Root-relative local links were rewritten to include the deployment base path \`$BASE_PATH\`."
  else
    echo "- Root-relative links such as \`/what-we-do/...\` resolve against the rebuilt hierarchy when hosted at the site root."
  fi
  echo "- Absolute \`https://incit.org/...\` links remain unchanged and should be normalized in a later pass if deployment will not use the original domain."
  echo "- Remote assets remain unchanged because no local asset mirror exists in the provided reference folder."
  echo "- Missing navbar landing pages were rebuilt as minimal section indexes or redirect aliases derived from available routes."
  echo "- Header and footer are centralized through \`components/header.html\` and \`components/footer.html\`; the build injects those shared blocks into all matching pages."
  echo "- The reusable \`incit-card\` popup system now uses shared assets in \`assets/incit-card-modal.css\` and \`assets/incit-card-modal.js\`, while each page keeps its own content."
  echo
  echo "## Duplicate Canonicals"
  echo
  if [[ -s "$DUPLICATES_TSV" ]]; then
    join -t $'\t' -1 1 -2 1 "$MANIFEST_CHOSEN" "$DUPLICATES_TSV" | \
      awk -F '\t' '{
        printf("- %s :: chosen %s (score %s) :: alternate %s (score %s)\n", $1, $3, $2, $8, $7)
      }'
  else
    echo "- None"
  fi
} > "$REPORTS_DIR/validation-report.md"

{
  echo "["
  first=1
  while IFS=$'\t' read -r route score source_file folder source_name canonical; do
    if [[ $first -eq 0 ]]; then
      echo ","
    fi
    first=0
    target_path="$SITE_DIR"
    if [[ "$route" == "/" ]]; then
      target_path="$SITE_DIR/index.html"
    else
      clean_route="${route#/}"
      clean_route="${clean_route%/}"
      target_path="$SITE_DIR/$clean_route/index.html"
    fi
    printf '  {"route":"%s","sourceFile":"%s","outputFile":"%s","canonicalUrl":"%s"}' \
      "$route" \
      "${source_file#"$ROOT_DIR"/}" \
      "${target_path#"$ROOT_DIR"/}" \
      "$canonical"
  done < "$MANIFEST_CHOSEN"
  echo
  echo "]"
} > "$REPORTS_DIR/site-map.json"

cat > "$REPORTS_DIR/build-summary.json" <<EOF
{
  "sourceHtmlFiles": $(wc -l < "$MANIFEST_ALL" | tr -d ' '),
  "generatedPages": $(wc -l < "$MANIFEST_CHOSEN" | tr -d ' '),
  "duplicateCanonicalRoutes": $(wc -l < "$DUPLICATES_TSV" | tr -d ' ')
}
EOF

echo "Built $(wc -l < "$MANIFEST_CHOSEN" | tr -d ' ') pages into $SITE_DIR"

#!/bin/bash
# Extract [Unreleased] section from CHANGELOG.md and generate release notes

set -e

CHANGELOG_FILE="${1:-CHANGELOG.md}"
OUTPUT_HTML="${2:-release-notes.html}"
OUTPUT_MD="${3:-release-notes.md}"

# Extract everything between [Unreleased] and the next ## section using awk
UNRELEASED=$(awk '
  /^## \[Unreleased\]/ { in_section=1; next }
  /^## / && in_section { exit }
  /^---$/ { next }
  in_section && NF { print }
' "$CHANGELOG_FILE")

# Check if we got anything
if [ -z "$UNRELEASED" ]; then
  echo "Warning: No [Unreleased] section found in CHANGELOG.md"
  UNRELEASED="### Added
- Bug fixes and improvements"
fi

# Generate HTML version for Sparkle
cat > "$OUTPUT_HTML" << 'HTML_TEMPLATE'
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      font-size: 13px;
      line-height: 1.6;
      color: #333;
      margin: 16px;
    }
    h2 {
      font-size: 16px;
      font-weight: 600;
      margin-top: 0;
      margin-bottom: 12px;
      color: #1d1d1f;
    }
    h3 {
      font-size: 14px;
      font-weight: 600;
      margin-top: 16px;
      margin-bottom: 8px;
      color: #1d1d1f;
    }
    ul {
      margin: 8px 0;
      padding-left: 24px;
    }
    li {
      margin: 4px 0;
    }
    strong {
      font-weight: 600;
    }
    code {
      background: #f5f5f7;
      padding: 2px 6px;
      border-radius: 3px;
      font-family: 'SF Mono', Monaco, 'Courier New', monospace;
      font-size: 12px;
    }
  </style>
</head>
<body>
  <h2>What's New in This Update</h2>
HTML_TEMPLATE

# Convert markdown to HTML (basic conversion)
in_list=false
while IFS= read -r line; do
  if [[ $line =~ ^###[[:space:]](.*) ]]; then
    # Close any open list
    if $in_list; then
      echo "  </ul>" >> "$OUTPUT_HTML"
      in_list=false
    fi
    # H3 heading
    echo "  <h3>${BASH_REMATCH[1]}</h3>" >> "$OUTPUT_HTML"
  elif [[ $line =~ ^-[[:space:]](.*) ]]; then
    # List item - handle bold **text** and code `text`
    item="${BASH_REMATCH[1]}"
    item=$(echo "$item" | sed -E 's/\*\*([^*]+)\*\*/<strong>\1<\/strong>/g')
    item=$(echo "$item" | sed -E 's/`([^`]+)`/<code>\1<\/code>/g')

    # Start list if needed
    if ! $in_list; then
      echo "  <ul>" >> "$OUTPUT_HTML"
      in_list=true
    fi
    echo "    <li>$item</li>" >> "$OUTPUT_HTML"
  fi
done <<< "$UNRELEASED"

# Close any open list
if $in_list; then
  echo "  </ul>" >> "$OUTPUT_HTML"
fi

# Close HTML
cat >> "$OUTPUT_HTML" << 'HTML_FOOTER'
</body>
</html>
HTML_FOOTER

# Generate Markdown version for GitHub releases
cat > "$OUTPUT_MD" << 'MD_HEADER'
## 🚀 What's New

MD_HEADER

echo "$UNRELEASED" >> "$OUTPUT_MD"

echo "" >> "$OUTPUT_MD"
echo "---" >> "$OUTPUT_MD"

echo "✓ Generated $OUTPUT_HTML and $OUTPUT_MD from CHANGELOG.md"

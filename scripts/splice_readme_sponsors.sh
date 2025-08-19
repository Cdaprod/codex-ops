#!/usr/bin/env bash
# splice_readme_sponsors.sh - insert docs/SPONSORS.md into README between markers.
# Usage: bash scripts/splice_readme_sponsors.sh
# Example: bash scripts/splice_readme_sponsors.sh
set -euo pipefail

README="README.md"
SPONSORS="docs/SPONSORS.md"
START="<!-- sponsors:start -->"
END="<!-- sponsors:end -->"

if [[ ! -f "$README" || ! -f "$SPONSORS" ]]; then
  echo "Required files missing" >&2
  exit 1
fi

SECTION=$(cat "$SPONSORS")
awk -v start="$START" -v end="$END" -v section="$SECTION" '
  $0==start {print; print section; inside=1; next}
  $0==end {inside=0; print; next}
  !inside {print}
' "$README" > "$README.tmp"
mv "$README.tmp" "$README"

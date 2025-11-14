#!/bin/zsh

# Usage examples:
#   ./filter_csv.sh PRODUCT123 file1.csv file2.csv ...
#   ls *2025*.csv | xargs ./filter_csv.sh PRODUCT123

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 SEARCH_TERM FILE [FILE ...]"
  exit 1
fi

search="$1"
shift  # shift args so "$@" is now the list of files

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
BOLD="\033[1m"
RESET="\033[0m"

for file in "$@"; do
  if [[ ! -f "$file" ]]; then
    echo -e "${YELLOW}⚠️  Warning:${RESET} '$file' not found, skipping."
    continue
  fi

  tmpfile="$(dirname "$file")/.$(basename "$file").tmp"

  before_count=$(wc -l < "$file" | tr -d ' ')

  # Keep header row
  head -n 1 "$file" > "$tmpfile"

  # Filter matching rows (case-insensitive, skip header)
  tail -n +2 "$file" | grep -i "$search" >> "$tmpfile" || true

  after_count=$(wc -l < "$tmpfile" | tr -d ' ')

  # Replace original file
  mv "$tmpfile" "$file"

  trimmed=$((before_count - after_count))
  percent=$(awk "BEGIN { if ($before_count > 0) printf \"%.1f\", (100 * $after_count / $before_count); else print 0 }")

  echo
  echo -e "${CYAN}📄 ${BOLD}${file}${RESET}"
  echo -e "   Before:  ${BOLD}${before_count}${RESET} lines"
  echo -e "   After:   ${GREEN}${after_count}${RESET} lines"
  echo -e "   Trimmed: ${RED}${trimmed}${RESET} lines (${BOLD}${percent}%${RESET} kept)"
  echo -e "   Filter term: '${YELLOW}${search}${RESET}'"
done

echo -e "\n${GREEN}✅ Filtering complete.${RESET}\n"

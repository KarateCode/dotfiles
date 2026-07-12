#!/bin/zsh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

if [[ -z "$1" ]]; then
    echo -e "${RED}Usage: grep-git-log.sh <EP-number>${RESET}"
    echo -e "Example: grep-git-log.sh 14006"
    exit 1
fi

ep_number="EP-$1"

# Find the first commit containing this EP
commit_info=$(git log --oneline --grep="$ep_number" -1 2>/dev/null)

if [[ -z "$commit_info" ]]; then
    echo -e "${RED}No commits found for ${BOLD}$ep_number${RESET}"
    exit 1
fi

commit_hash=$(echo "$commit_info" | awk '{print $1}')
commit_full_hash=$(git rev-parse "$commit_hash")

# Get all version bump commits (newest first)
version_bumps=$(git log --oneline --grep="^version bump: v[0-9]" --format="%H %s" 2>/dev/null | grep "version bump: v[0-9]")

# Find which version this commit belongs to
found_version=""

while IFS= read -r bump_line; do
    [[ -z "$bump_line" ]] && continue

    bump_hash=$(echo "$bump_line" | awk '{print $1}')
    bump_version=$(echo "$bump_line" | sed 's/.*version bump: //')

    # Check if the EP commit is an ancestor of this version bump
    if git merge-base --is-ancestor "$commit_full_hash" "$bump_hash" 2>/dev/null; then
        found_version="$bump_version"
        # Don't break - keep looking for older versions to find the earliest one that contains it
    else
        # Once we find a version bump that doesn't contain the commit,
        # the previous found_version is the one where it was first released
        break
    fi
done <<< "$version_bumps"

# Display results
echo ""
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  Ticket:${RESET}    ${YELLOW}$ep_number${RESET}"
echo -e "${BOLD}  Commit:${RESET}    ${BLUE}$commit_hash${RESET}"

if [[ -z "$found_version" ]]; then
    echo -e "${BOLD}  Version:${RESET}   ${RED}${BOLD}unreleased${RESET} ${RED}(not yet in a version bump)${RESET}"
else
    echo -e "${BOLD}  Version:${RESET}   ${GREEN}${BOLD}$found_version${RESET}"
fi

echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${BOLD}  Message:${RESET}"
echo -e "    $(echo "$commit_info" | cut -d' ' -f2-)"
echo ""

#!/bin/zsh

# Get first modified (unstaged) file
first_modified=$(git ls-files -m | head -n 1)

if [[ -n "$first_modified" ]]; then
    # Show diff of the first modified file
    git diff "$first_modified"
    exit 0
fi

# No modified files — check for untracked files
first_untracked=$(git ls-files --others --exclude-standard | head -n 1)

if [[ -n "$first_untracked" ]]; then
    # Show contents of the first untracked file
    bat "$first_untracked"
    exit 0
fi

# No modified or untracked files
echo "No modified or untracked files."

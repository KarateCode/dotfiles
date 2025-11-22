#!/bin/zsh

# Get first modified (unstaged) file
first_modified=$(git ls-files -m | head -n 1)

if [[ -n "$first_modified" ]]; then
    git add "$first_modified"
    git status
    exit 0
fi

# No modified files — check for untracked ones
first_untracked=$(git ls-files --others --exclude-standard | head -n 1)

if [[ -n "$first_untracked" ]]; then
    git add "$first_untracked"
    git status
    exit 0
fi

# Nothing to add
echo "Nothing to add."
git status

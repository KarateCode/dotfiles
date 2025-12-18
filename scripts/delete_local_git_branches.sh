#!/bin/zsh

selected_branches=$(git branch | gum choose --header="Choose local git branches to delete locally" --no-limit)

if [[ -z "$selected_branches" ]]; then
    echo "No branches selected."
    return 0
fi

while IFS= read -r branch; do
    trimmed_branch=$(echo "$branch" | xargs)
    # echo "Removing local branch: '$trimmed_branch'"
    git branch -D "$trimmed_branch"
done <<< "$selected_branches"

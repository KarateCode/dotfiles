#!/bin/zsh

selected_files=$(ls | gum choose --header="Choose which files to delete" --no-limit)

if [[ -z "$selected_files" ]]; then
    echo "No files selected."
    return 0
fi

while IFS= read -r branch; do
    trimmed_file=$(echo "$branch" | xargs)
    echo "Removing local file: '$trimmed_file'"
    rm "$trimmed_file"
done <<< "$selected_files"

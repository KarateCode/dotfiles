#!/bin/zsh

# 1. Get the most recent file in Downloads
# The (N) qualifier ensures the script doesn't error if the folder is empty
target_file=(~/Downloads/*(om[1]N))
echo $target_file

# 2. Check if a file actually exists
if [[ -n "$target_file" ]]; then
    # Extract just the filename for the notification
    file_name="${target_file:t}"

    # 3. Perform the deletion
    rm "$target_file"

    # 4. Trigger the macOS notification
    osascript -e "display notification \"Deleted: $file_name\" with title \"Download Cleanup\""
else
    osascript -e "display notification \"No files found in ~/Downloads\" with title \"Download Cleanup Error\""
fi

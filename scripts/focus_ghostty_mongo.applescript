#!/usr/bin/osascript

# @raycast.schemaVersion 1
# @raycast.title Focus Mongo Ghostty
# @raycast.mode silent

# CONFIGURATION: Change "mongo" to match your specific tmux session name
property targetSession : "mongo"

tell application "System Events"
    if exists process "Ghostty" then
        tell process "Ghostty"
            set windowFound to false
            -- Loop through every open Ghostty window
            set allWindows to windows
            repeat with aWindow in allWindows
                set windowTitle to title of aWindow
                -- Check if your target tmux session name is inside the window's title string
                if windowTitle contains targetSession then
                    -- Bring Ghostty to the front and focus that specific window
                    set frontmost to true
                    perform action "AXRaise" of aWindow
                    set windowFound to true
                    exit repeat
                end if
            end repeat
            
            -- Optional: If the window wasn't found, you can optionally notify yourself
            if not windowFound then
                do shell script "osascript -e 'display notification \"No active Ghostty window found with tmux session: " & targetSession & "\" with title \"Workspace Error\"'"
            end if
        end tell
    end if
end tell

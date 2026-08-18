#!/bin/bash
# Enter herdr copy-mode with emacs keybindings and start search

# Set Karabiner variable to enable emacs copy-mode keybindings
'/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli' --set-variables '{"herdr_emacs_copy_mode":1}'

# Send keystrokes to Ghostty via AppleScript
# ctrl+a enters prefix mode, [ enters copy-mode, / starts search
osascript -e '
tell application "System Events"
    tell process "ghostty"
        keystroke "a" using control down
        delay 0.1
        keystroke "["
        delay 0.1
        keystroke "/"
    end tell
end tell
'

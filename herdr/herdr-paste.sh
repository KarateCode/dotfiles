#!/bin/bash
# Smart paste: pass F4 to Emacs, otherwise paste from clipboard

# Get current process in pane
process=$(herdr pane process-info "$HERDR_ACTIVE_PANE_ID" 2>/dev/null | jq -r '.result.name // empty')

if [[ "$process" == "emacs" ]] || [[ "$process" == emacs-* ]]; then
    # In Emacs - send F4 through
    herdr pane send-keys "$HERDR_ACTIVE_PANE_ID" f4
else
    # Normal paste - get clipboard and send as text
    clipboard=$(pbpaste)
    if [[ -n "$clipboard" ]]; then
        herdr pane send-text "$HERDR_ACTIVE_PANE_ID" "$clipboard"
    fi
fi

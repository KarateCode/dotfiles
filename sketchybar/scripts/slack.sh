# #!/bin/bash
# # scripts/slack.sh - Slack unread badge fetcher for SketchyBar

# SLACK_INFO=$(lsappinfo info -only StatusLabel `lsappinfo find LSDisplayName=Slack` 2>/dev/null)
# COUNT=$(echo "$SLACK_INFO" | sed -E 's/.*StatusLabel="([0-9]+)".*/\1/')

# if [[ "$COUNT" =~ ^[0-9]+$ ]]; then
#     echo "label=$COUNT icon=󰒱"
# else
#     echo "label=67 icon=󰒱"
# fi


#!/bin/bash
# scripts/slack.sh - Slack unread badge fetcher for SketchyBar

# SLACK_INFO=$(lsappinfo info -only StatusLabel "$(lsappinfo find LSDisplayName=Slack)" 2>/dev/null)
# COUNT=$(echo "$SLACK_INFO" | sed -E 's/.*StatusLabel="([0-9]+)".*/\1/')

# ITEM_NAME="$NAME"   # SketchyBar provides this automatically

# if [[ "$COUNT" =~ ^[0-9]+$ ]]; then
#     VALUE="$COUNT"
# else
#     VALUE=""   # test value
# fi

# echo $VALUE

# # Update the item
# sketchybar --set "$ITEM_NAME" label="$VALUE" icon="󰒱"

#!/bin/bash

# # Fetch Slack unread badge info
# SLACK_INFO=$(lsappinfo info -only StatusLabel "$(lsappinfo find LSDisplayName=Slack)" 2>/dev/null)
# # COUNT=$(echo "$SLACK_INFO" | sed -E 's/.*StatusLabel="([0-9]+)".*/\1/')
# COUNT=67

# ITEM="$NAME"

# if [[ "$COUNT" =~ ^[0-9]+$ && "$COUNT" -gt 0 ]]; then
#     # Show label + badge
#     sketchybar --set "$ITEM" label="$COUNT" label.drawing=on label.background.drawing=on
# else
#     # No unread messages → hide badge + clear label
#     sketchybar --set "$ITEM" label="" label.drawing=off label.background.drawing=off
# fi

#!/bin/bash

# Get Slack badge info block
SLACK_INFO=$(lsappinfo info -only StatusLabel "$(lsappinfo find LSDisplayName=Slack)" 2>/dev/null)

# Extract the "label" field from:  "StatusLabel"={ "label"="•" }
# Works for dots (•), numbers, or empty
SLACK_LABEL=$(echo "$SLACK_INFO" | sed -nE 's/.*"label"="([^"]+)".*/\1/p')

ITEM="$NAME"

# The badge is considered "present" if SLACK_LABEL is not empty
if [[ -n "$SLACK_LABEL" ]]; then
    # Show badge – display dot or number exactly as Slack provides
    sketchybar --set "$ITEM" \
               label="$SLACK_LABEL" \
               label.drawing=on \
               label.background.drawing=on
else
    # No unread messages → hide badge and clear label
    sketchybar --set "$ITEM" \
               label="" \
               label.drawing=off \
               label.background.drawing=off
fi


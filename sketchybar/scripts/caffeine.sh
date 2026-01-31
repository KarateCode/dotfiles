#!/bin/bash

NAME="widgets.caffeine"

# If called with "toggle" argument, toggle caffeinate
if [ "$1" = "toggle" ]; then
  if pgrep -x "caffeinate" > /dev/null; then
    killall caffeinate
  else
    caffeinate -d &
  fi
fi

# Update icon based on current state
if pgrep -x "caffeinate" > /dev/null; then
  sketchybar --set $NAME icon="󰛊" icon.color=0xffe7c664
else
  sketchybar --set $NAME icon="󰒲" icon.color=0xff7f8490
fi

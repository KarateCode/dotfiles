#!/bin/zsh

# Pop an fzf menu of the available audio outputs and switch to the selected
# one. The output currently in use is marked with an asterisk.
#
# Two wrinkles on this machine, both learned the hard way:
#
#   * Sinks whose active port is "not available" (the T2 headphone jack with
#     nothing plugged in) still show up in `pactl list sinks`. Selecting one
#     silently does nothing -- WirePlumber refuses and falls back by
#     priority.session, see wireplumber.conf.d/apple-t2-headphone-autoswitch.conf.
#     So those are filtered out rather than offered as a dead end.
#
#   * `set-default-sink` only affects NEW streams, so anything already playing
#     is moved across too.

set -euo pipefail

current=$(pactl get-default-sink)

# marker <TAB> friendly description <TAB> sink name
# fzf shows the first two fields; the sink name rides along hidden.
menu=$(pactl list sinks | awk -v cur="$current" '
  function flush() {
    if (name == "") return
    # No ports at all, or an active port that is not explicitly unavailable.
    if (active != "" && (active in avail) && avail[active] == 0) return
    printf "%s\t%s\t%s\n", (name == cur ? "*" : " "), desc, name
  }
  /^Sink #/ { flush(); name = ""; desc = ""; active = ""; delete avail }
  /^[[:space:]]+Name: /        && name == "" { name = substr($0, index($0, ": ") + 2) }
  /^[[:space:]]+Description: / && desc == "" { desc = substr($0, index($0, ": ") + 2) }
  /\(type: / {
    port = substr($0, 1, index($0, ": ") - 1)
    gsub(/^[ \t]+/, "", port)
    avail[port] = ($0 ~ /not available/) ? 0 : 1
  }
  /^[[:space:]]+Active Port: / { active = substr($0, index($0, ": ") + 2) }
  END { flush() }
')

if [[ -z "$menu" ]]; then
  print -u2 "No audio outputs available."
  exit 1
fi

choice=$(print -r -- "$menu" | fzf \
  --delimiter='\t' \
  --with-nth=1,2 \
  --height='~40%' \
  --reverse \
  --prompt='Audio output> ' \
  --header='* = current output') || exit 0

sink=${choice##*$'\t'}
label=$(print -r -- "$choice" | cut -f2)

pactl set-default-sink "$sink"

# Drag anything mid-playback over to the new sink.
pactl list short sink-inputs | while read -r id _rest; do
  pactl move-sink-input "$id" "$sink" 2>/dev/null || true
done

print -r -- "Audio output: $label"

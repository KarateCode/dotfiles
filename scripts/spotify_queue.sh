#!/bin/zsh

# A live view of the Spotify queue, meant to sit in its own tmux pane next to
# spotify_player.
#
# Why this exists: playing a bare list of track URIs is broken (Enter on a
# search result or in Liked Tracks returns 403 "Restriction violated" -- see
# spotify-player#1113 and librespot#1870), so queueing with Z and skipping with
# n is the way to play those. That makes the queue load-bearing, and
# spotify_player only shows it in a popup that covers the page you were on.
#
# Everything goes through spotify_player's own CLI rather than the Web API
# directly, so this reuses the running instance's token and client id -- no
# second login, no second quota, nothing to refresh here.
#
# Usage: spotify_queue.sh [seconds]   (default 20)
#        r refreshes now, q quits.

# Deliberately no `set -e`: a poll that fails because the player is restarting
# should redraw a message, not kill the pane.
set -uo pipefail

interval=${1:-20}

# Dracula, to match the spotify_player theme.
purple=$'\e[38;2;189;147;249m'
green=$'\e[38;2;80;250;123m'
cyan=$'\e[38;2;139;233;253m'
pink=$'\e[38;2;255;121;198m'
comment=$'\e[38;2;98;114;164m'
fg=$'\e[38;2;248;248;242m'
bold=$'\e[1m'
reset=$'\e[0m'
erase=$'\e[K'   # clear to end of line, so a rewritten line leaves no tail behind

cleanup() {
  # Show the cursor again and drop back out of the alternate screen, so the
  # pane is left as it was found.
  printf '\e[?25h\e[?1049l'
}
trap cleanup EXIT INT TERM

printf '\e[?1049h\e[?25l'

# Cut to a visible width, appending an ellipsis when it actually had to cut.
fit() {
  local s=$1 w=$2
  (( w < 1 )) && return
  if (( ${#s} > w )); then
    print -r -- "${s[1,w-1]}…"
  else
    print -r -- "$s"
  fi
}

# Drop detail rather than wrap when the pane is narrow.
footer() {
  local cols=$1 f
  f="  [r] refresh   [q] quit   polling every ${interval}s"
  (( ${#f} > cols )) && f="  [r] refresh   [q] quit"
  (( ${#f} > cols )) && f="  r refresh  q quit"
  (( ${#f} > cols )) && f="  r/q"
  print -r -- "$f"
}

# The title bar, kept separate from the body because its clock ticks on every
# poll and would otherwise make every frame look like a change.
header() {
  local cols=$1 stamp
  stamp="    updated $(date +%H:%M:%S)"
  (( 15 + ${#stamp} > cols )) && stamp=""
  print -r -- "${purple}${bold}  SPOTIFY QUEUE${reset}${comment}${stamp}${reset}${erase}"
}

# Everything below the header, built into a string rather than printed, so a
# poll that changed nothing can be dropped instead of repainting the pane.
build_body() {
  local cols=$1 rows=$2
  local queue current track artist album n shown max tw aw

  # Check for a running instance first. With none, `get key queue` still
  # answers -- it spins up a throwaway client and returns an empty queue, which
  # would render as "queue is empty" and bill an API call for the privilege.
  if ! pgrep -x spotify_player &>/dev/null; then
    print -r -- "${comment}$(fit "  spotify_player isn't running." $cols)${reset}"
    print
    print -r -- "${comment}$(footer $cols)${reset}"
    return
  fi

  queue=$(spotify_player get key queue 2>/dev/null)

  if [[ -z "$queue" || "$queue" == "null" ]]; then
    print -r -- "${comment}$(fit "  Connecting..." $cols)${reset}"
    print
    print -r -- "${comment}$(footer $cols)${reset}"
    return
  fi

  current=$(print -r -- "$queue" | jq -r '.currently_playing // empty' 2>/dev/null)
  if [[ -n "$current" ]]; then
    track=$(print -r -- "$current" | jq -r '.name // ""')
    artist=$(print -r -- "$current" | jq -r '[.artists[]?.name] | join(", ")')
    album=$(print -r -- "$current" | jq -r '.album.name // ""')
    print -r -- "  ${green}▶${reset} ${fg}${bold}$(fit "$track" $((cols-6)))${reset}"
    [[ -n "$artist" ]] && print -r -- "    ${cyan}$(fit "$artist" $((cols-6)))${reset}"
    [[ -n "$album" ]] && print -r -- "    ${comment}$(fit "$album" $((cols-6)))${reset}"
  else
    print -r -- "  ${comment}Nothing playing.${reset}"
  fi
  print

  # Leave room for the header, the now-playing block and the footer.
  max=$(( rows - 11 ))
  (( max < 1 )) && max=1

  shown=$(print -r -- "$queue" | jq -r --argjson max "$max" \
    '[.queue[]? | "\(.name)\t\([.artists[]?.name] | join(", "))"] | .[0:$max] | .[]' 2>/dev/null)

  if [[ -z "$shown" ]]; then
    print -r -- "  ${comment}Queue is empty. Add tracks with Z in spotify_player.${reset}"
  else
    print -r -- "  ${pink}${bold}UP NEXT${reset}"

    # Number and gutters take 8 columns; split the rest 60/40 track/artist.
    # Computed once -- re-running `local` per iteration makes zsh echo the
    # value of an already-declared variable, which prints junk into the pane.
    tw=$(( (cols - 8) * 6 / 10 ))
    (( tw < 10 )) && tw=10
    aw=$(( cols - 8 - tw - 2 ))
    (( aw < 6 )) && aw=6

    n=0
    while IFS=$'\t' read -r track artist; do
      (( ++n ))
      # Pad with zsh's ${(r:N:)}, which counts characters. printf '%-*s' pads
      # by bytes, so an ellipsis or any accented name skews the column.
      track=$(fit "$track" $tw)
      print -r -- "  ${comment}${(l:2:)n}${reset}  ${fg}${(r:$tw:)track}${reset}  ${cyan}$(fit "$artist" $aw)${reset}"
    done <<< "$shown"
  fi

  print
  print -r -- "${comment}$(footer $cols)${reset}"
}

draw() {
  local cols rows body frame
  # Inside tmux, ask tmux: `tput` reports the terminal size, which is not the
  # pane size once the window is split, and every line would wrap.
  if [[ -n "${TMUX:-}" ]]; then
    cols=$(tmux display -p '#{pane_width}' 2>/dev/null)
    rows=$(tmux display -p '#{pane_height}' 2>/dev/null)
  fi
  [[ -n "${cols:-}" ]] || cols=$(tput cols 2>/dev/null) || cols=80
  [[ -n "${rows:-}" ]] || rows=$(tput lines 2>/dev/null) || rows=24

  body=$(build_body $cols $rows)
  # Size is part of the frame: a resize changes the layout even when the queue
  # behind it is identical.
  frame="${cols}x${rows}|${body}"

  if [[ "$frame" == "$last_frame" ]]; then
    # Nothing moved. Rewriting the one header line in place keeps the clock
    # honest without the clear-and-repaint that causes the flicker.
    printf '\e[H'
    header $cols
    return
  fi

  # \e[H homes the cursor and \e[J clears from there down.
  printf '\e[H\e[J'
  header $cols
  print
  print -r -- "$body"
  last_frame=$frame
}

last_frame=""
while true; do
  draw
  # A timed read gives the poll interval and the keybinds in one: it wakes
  # early on a keypress, and otherwise times out and polls again.
  if read -t "$interval" -k 1 key 2>/dev/null; then
    case "$key" in
      q|Q) break ;;
    esac
  fi
done

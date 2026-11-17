#!/bin/zsh

# Repair spotify_player when it launches fine but refuses to play anything.
#
# Symptom: the TUI opens, the library loads from cache, but pressing Enter does
# nothing at all -- no error in the UI. ~/.cache/spotify-player/*.log shows:
#
#   couldn't load context info because: context is not available. type: Default
#   didn't find initial track: the current track couldn't be resolved from the transfer state
#   failed to handle request: Invalid state { could not find track None in context of N }
#   Connection failed: http error: status code 500 ... device_id=...
#
# Cause: the Spotify Connect state held server-side on the account has gone
# stale -- it points at a context whose current track can no longer be resolved.
# On startup spotify_player registers its integrated librespot device and then
# transfers playback onto it with PUT /v1/me/player. librespot rejects that
# state, Spotify answers 500, and all 3 retries fail. With no ACTIVE device,
# every later play request returns 404 "Device not found" -- including plays
# from a playlist, which is why nothing works rather than just some things.
#
# The 429s that fill the log are a red herring: on any 4xx spotify_player
# retries through the shared ncspot client id, whose quota is permanently
# exhausted (see the comment block in spotify-player/app.toml). So it reads as
# rate limiting when it is really the failed device transfer upstream of it.
#
# Fix: play one real context, which overwrites the bad state with a resolvable
# one. Afterwards spotify_player logs "Connection succeeded!" on retry=0 again.
# Done at volume 0 and paused immediately, so the repair is silent.
#
# Everything goes through spotify_player's own CLI rather than the Web API, so
# there is no token handling here -- the running instance refreshes its own.
#
# NOTE: this does not fix playing a bare list of track URIs, i.e. Enter on a
# search result or inside Liked Tracks. That returns 403 "Restriction violated"
# because librespot 0.8.0 cannot resolve an ad-hoc context, and it is still
# broken in spotify-player 0.25.2. Queue those instead: Z, then n.

set -euo pipefail

started_daemon=0
volume=""

# librespot coalesces volume changes ("delayed volume update for all devices"),
# and one issued immediately after a pause gets dropped -- so set it, read it
# back, and retry rather than firing once and hoping.
restore_volume() {
  [[ -z "$volume" ]] && return 0
  for _ in {1..5}; do
    spotify_player playback volume "$volume" &>/dev/null || true
    sleep 1
    [[ $(spotify_player get key devices 2>/dev/null | jq -r '.[0].volume_percent // empty') == "$volume" ]] && return 0
  done
  print -u2 -- "Warning: could not restore the volume to ${volume}%."
}

cleanup() {
  # Always hand the volume back, even if the repair bailed out partway, and
  # always before stopping a daemon we started -- after that there is no device
  # left to set it on.
  restore_volume
  (( started_daemon )) && pgrep -x spotify_player | xargs -r kill 2>/dev/null || true
}
trap cleanup EXIT

if ! pgrep -x spotify_player &>/dev/null; then
  print -r -- "Starting spotify_player..."
  nohup spotify_player --daemon &>/dev/null &
  started_daemon=1
fi

# The device only exists once librespot has authenticated and registered it,
# which takes a few seconds on a cold start.
# The CLI exits non-zero while the daemon is still coming up, which under
# `set -e` would abort the script mid-wait -- hence `|| true` on every query.
device=""
for _ in {1..40}; do
  device=$(spotify_player get key devices 2>/dev/null | jq -r '.[0] // empty' || true)
  [[ -n "$device" ]] && break
  sleep 1
done

if [[ -z "$device" ]]; then
  print -u2 -- "No spotify-player device registered. Is the network up, and is the account still authenticated?"
  exit 1
fi

volume=$(print -r -- "$device" | jq -r '.volume_percent // 70' || true)

# Prefer a playlist; fall back to a saved album if there are none.
context_type=playlist
id=$(spotify_player get key user-playlists 2>/dev/null | jq -r '.[0].id // empty' || true)
if [[ -z "$id" ]]; then
  context_type=album
  id=$(spotify_player get key user-saved-albums 2>/dev/null | jq -r '.[0].id // empty' || true)
fi

if [[ -z "$id" ]]; then
  print -u2 -- "No playlist or saved album to replay -- cannot rebuild the playback state."
  exit 1
fi

# The device registers a second or two before the player will accept commands.
# Muting doubles as the readiness probe, so we cannot start the repair playback
# while the volume is still up and blare out of the speakers.
for _ in {1..30}; do
  spotify_player playback volume 0 &>/dev/null && break
  sleep 1
done

# Checking `is_playing` is no good -- spotify_player reports it from a cached
# state that lags, and it still reads true well after a pause. What actually
# matters is that the context resolved and a track loaded off it, which is
# exactly the state the stale-transfer bug could not produce.
rebuilt=0
for _ in {1..3}; do
  spotify_player playback start context "$context_type" --id "$id" &>/dev/null || true
  for _ in {1..10}; do
    sleep 1
    playback=$(spotify_player get key playback 2>/dev/null || true)
    [[ -z "$playback" ]] && continue
    context=$(print -r -- "$playback" | jq -r '.context.uri // empty' 2>/dev/null || true)
    track=$(print -r -- "$playback" | jq -r '.item.name // empty' 2>/dev/null || true)
    if [[ "$context" == *"$id"* && -n "$track" ]]; then
      rebuilt=1
      break
    fi
  done
  (( rebuilt )) && break
done

spotify_player playback pause &>/dev/null || true

if (( rebuilt )); then
  print -r -- "Playback state rebuilt from $context_type $id (\"$track\")."
  print -r -- "Restart spotify_player -- it should log \"Connection succeeded!\" and Enter should work again."
else
  print -u2 -- "Could not rebuild the playback state. Check the newest log in ~/.cache/spotify-player/."
  exit 1
fi

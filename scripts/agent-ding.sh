#!/bin/zsh
# Ding on AI agent status change. Called with the same status workmux tracks.
# waiting = agent has a question, done = agent finished. Anything else is silent.
# Set AGENT_DING=0 to mute.

[[ "${AGENT_DING:-1}" == "0" ]] && exit 0

case "${1:-}" in
    waiting) sound=/usr/share/sounds/freedesktop/stereo/message.oga ;;
    done)    sound=/usr/share/sounds/freedesktop/stereo/complete.oga ;;
    *)       exit 0 ;;
esac

[[ -r "$sound" ]] || exit 0

# Detached: an agent hook must never block waiting for audio to finish.
setsid -f pw-play --volume="${AGENT_DING_VOLUME:-0.5}" "$sound" >/dev/null 2>&1
exit 0

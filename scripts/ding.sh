#!/bin/zsh
#
# ding.sh -- play a short sound for a workflow event.
#
# Generalized out of agent-ding.sh, which now shims to this. Two consumers:
#
#   AI agents (~/.claude/settings.json hooks, via agent-ding.sh)
#     waiting  agent has a question
#     done     agent finished
#
#   ntc test suites (scripts/ntc-slot.sh)
#     pass     all four suites green
#     fail     at least one suite red
#
# Anything else exits silently, on purpose: these are hooks, and an unknown
# event must never be noisy or non-zero.
#
# SOUND CHOICE IS LOAD-BEARING, not decoration. The tmux window glyph is only
# visible while attached to the session running the suite, and ntc windows do
# not show up in the workmux sidebar at all -- so when the window is off
# screen the sound is the ONLY signal, and it has to be told apart from an
# agent ding by ear alone.
#
# Linux (freedesktop):
#   waiting  message.oga       0.31s  single soft tone
#   done     complete.oga      1.09s  long chime
#   pass     bell.oga x2       0.14s each, ~120ms apart
#   fail     dialog-error.oga  0.50s  low buzz
#
# macOS:
#   waiting  Ping.aiff         single soft tone
#   done     Glass.aiff        pleasant chime
#   pass     Pop.aiff x2       quick double pop
#   fail     Basso.aiff        low error tone
#
# `pass` is deliberately distinguished by RHYTHM rather than timbre. Nothing
# else in this setup emits a double pip, so it is recognizable without
# comparing tones against complete.oga/Glass.aiff.
#
# Mute: AGENT_DING=0 silences waiting/done, NTC_DING=0 silences pass/fail.
# They are separate so test notifications can be killed without losing agent
# notifications, and vice versa.
# Volume: AGENT_DING_VOLUME, default 0.5.

set -u

typeset sound
typeset -i pips=1

if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    SOUNDS=/System/Library/Sounds
    case "${1:-}" in
        waiting)
            [[ "${AGENT_DING:-1}" == "0" ]] && exit 0
            sound=$SOUNDS/Ping.aiff ;;
        done)
            [[ "${AGENT_DING:-1}" == "0" ]] && exit 0
            sound=$SOUNDS/Glass.aiff ;;
        pass)
            [[ "${NTC_DING:-1}" == "0" ]] && exit 0
            sound=$SOUNDS/Pop.aiff; pips=2 ;;
        fail)
            [[ "${NTC_DING:-1}" == "0" ]] && exit 0
            sound=$SOUNDS/Basso.aiff ;;
        *)
            exit 0 ;;
    esac

    [[ -r "$sound" ]] || exit 0

    vol="${AGENT_DING_VOLUME:-0.5}"

    # Detached, always. A hook that blocks for the length of a sound file would
    # stall an agent hook or, worse, hold up the shell prompt in a test pane right
    # when the suite finishes.
    if (( pips > 1 )); then
        ( for (( i = 1; i <= pips; i++ )); do
            afplay -v "$vol" "$sound"
            (( i < pips )) && sleep 0.12
        done ) &>/dev/null &
        disown
    else
        afplay -v "$vol" "$sound" &>/dev/null &
        disown
    fi
else
    # Linux (freedesktop)
    SOUNDS=/usr/share/sounds/freedesktop/stereo
    case "${1:-}" in
        waiting)
            [[ "${AGENT_DING:-1}" == "0" ]] && exit 0
            sound=$SOUNDS/message.oga ;;
        done)
            [[ "${AGENT_DING:-1}" == "0" ]] && exit 0
            sound=$SOUNDS/complete.oga ;;
        pass)
            [[ "${NTC_DING:-1}" == "0" ]] && exit 0
            sound=$SOUNDS/bell.oga; pips=2 ;;
        fail)
            [[ "${NTC_DING:-1}" == "0" ]] && exit 0
            sound=$SOUNDS/dialog-error.oga ;;
        *)
            exit 0 ;;
    esac

    [[ -r "$sound" ]] || exit 0

    vol="${AGENT_DING_VOLUME:-0.5}"

    # Detached, always.
    if (( pips > 1 )); then
        setsid -f zsh -c '
            integer i
            for (( i = 1; i <= $3; i++ )); do
                pw-play --volume="$1" "$2"
                (( i < $3 )) && sleep 0.12
            done
        ' ding "$vol" "$sound" "$pips" >/dev/null 2>&1
    else
        setsid -f pw-play --volume="$vol" "$sound" >/dev/null 2>&1
    fi
fi

exit 0

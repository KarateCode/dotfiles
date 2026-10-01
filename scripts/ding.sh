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
#   waiting  message.oga       0.31s  single soft tone
#   done     complete.oga      1.09s  long chime
#   pass     bell.oga x2       0.14s each, ~120ms apart
#   fail     dialog-error.oga  0.50s  low buzz
#
# `pass` is deliberately distinguished by RHYTHM rather than timbre. Nothing
# else in this setup emits a double pip, so it is recognizable without
# comparing tones against complete.oga. Picking another short one-shot sound
# would have meant learning to tell two similar single tones apart, which is
# exactly the thing that fails when you are not listening for it.
#
# alarm-clock-elapsed.oga was the obvious "timer finished" candidate and is
# rejected: 6.1 seconds.
#
# Mute: AGENT_DING=0 silences waiting/done, NTC_DING=0 silences pass/fail.
# They are separate so test notifications can be killed without losing agent
# notifications, and vice versa.
# Volume: AGENT_DING_VOLUME, default 0.5.

set -u

SOUNDS=/usr/share/sounds/freedesktop/stereo

typeset sound
typeset -i pips=1

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

# Detached, always. A hook that blocks for the length of a sound file would
# stall an agent hook or, worse, hold up the shell prompt in a test pane right
# when the suite finishes.
#
# The multi-pip case runs the whole sequence inside ONE detached shell rather
# than firing N background players, so the gap is actually a gap -- concurrent
# pw-play processes would overlap into a single blurred tone.
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

exit 0

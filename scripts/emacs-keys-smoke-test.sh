#!/usr/bin/env bash
# Smoke test for GTK "Emacs" key-theme bindings (C-f/C-b/M-f/M-b/C-d/M-d/...)
# in Chromium -- both web page text fields and the address bar.
#
# WHY THE SETTING IS EASY TO GET WRONG
#   ~/.config/gtk-3.0/settings.ini is NOT enough on Hyprland. GTK3 resolves
#   settings through xdg-desktop-portal, and a value served by the portal
#   outranks settings.ini. The portal is backed by the gsettings key
#   org.gnome.desktop.interface gtk-key-theme -- that is the one that wins.
#
# CONTAINMENT
#   This test drives Chromium with synthetic keystrokes. wtype injects into
#   whatever the compositor has focused, so running it against your live
#   Hyprland session sprays keys into whatever window happens to be focused.
#   Instead we start `cage` (a one-app kiosk compositor) nested inside your
#   session. It gets its OWN WAYLAND_DISPLAY socket, and every wtype /
#   wl-copy / wl-paste call here is pinned to that socket. Keystrokes
#   therefore cannot reach your real session, even if focus changes, even if
#   you keep typing while the test runs.
#
#   A small cage window will appear for the duration. Ignore it; you do not
#   need to focus it, and focusing it will not affect the results.
#
# READBACK
#   web textarea : page writes caret+text into document.title, read over the
#                  DevTools HTTP endpoint (/json) -- no websocket client needed
#   omnibox      : Home, shift-End, C-c, then read the NESTED clipboard
#
# Usage: scripts/emacs-keys-smoke-test.sh [--keep] [--show]
#   --keep   leave the temp dir (profile, logs, page) behind for inspection
#   --show   stream cage/chromium logs to stderr

set -uo pipefail

PORT=${PORT:-9333}
ATTEMPTS=${ATTEMPTS:-3}      # wtype drops a keystroke every ~20 injections
WORKDIR=$(mktemp -d /tmp/emacs-keys-smoke.XXXXXX)
HTML="$WORKDIR/test.html"
CAGELOG="$WORKDIR/cage.log"
ENVFILE="$WORKDIR/nested-display"
KEEP=0; SHOW=0
for a in "$@"; do case $a in --keep) KEEP=1;; --show) SHOW=1;; esac; done

PASS=0; FAIL=0; WD=""
G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; N=$'\033[0m'

cleanup() {
  pkill -f "user-data-dir=$WORKDIR/profile" 2>/dev/null
  sleep 0.5
  [[ -n "${CAGE_PID:-}" ]] && kill "$CAGE_PID" 2>/dev/null
  if (( KEEP )); then echo "artifacts kept in $WORKDIR"; else rm -rf "$WORKDIR" 2>/dev/null; fi
}
trap cleanup EXIT

for t in cage chromium wtype wl-copy wl-paste jq curl python3 gsettings; do
  command -v "$t" >/dev/null || { echo "missing required tool: $t" >&2; exit 1; }
done

enc() { python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1],safe=""))' "$1"; }

# Every synthetic-input call goes through these. They are the containment
# boundary: nothing here ever touches $WAYLAND_DISPLAY of the real session.
key()  { WAYLAND_DISPLAY="$WD" wtype "$@"; }
clip() { WAYLAND_DISPLAY="$WD" wl-paste --no-newline 2>/dev/null; }
clip_clear() { WAYLAND_DISPLAY="$WD" wl-copy --clear 2>/dev/null; }

# ========================== stage 1: configuration ===========================
echo
echo "=== configuration ==="
printf '  %-24s %s\n' "settings.ini" \
  "$(sed -n 's/^ *gtk-key-theme-name *= *//p' ~/.config/gtk-3.0/settings.ini 2>/dev/null || echo '(unset)')"
printf '  %-24s %s\n' "gsettings" "$(gsettings get org.gnome.desktop.interface gtk-key-theme)"
printf '  %-24s %s\n' "xdg portal" \
  "$(busctl --user call org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop \
      org.freedesktop.portal.Settings Read ss org.gnome.desktop.interface gtk-key-theme \
      2>/dev/null | sed 's/^v v s //' || echo '(portal unavailable)')"

EFFECTIVE=$(python3 - <<'PY' 2>/dev/null
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk
print(Gtk.Settings.get_default().get_property('gtk-key-theme-name'))
PY
)
printf '  %-24s %s\n' "effective (live GTK3)" "${EFFECTIVE:-<probe failed>}"
if [[ "$EFFECTIVE" != "Emacs" ]]; then
  echo
  echo "  ${R}GTK is not using the Emacs key theme.${N} Fix with:"
  echo "    gsettings set org.gnome.desktop.interface gtk-key-theme 'Emacs'"
  echo "  Continuing so you can see exactly what fails."
fi

# =============================== test page ===================================
cat > "$HTML" <<'HTMLEOF'
<!DOCTYPE html><html><head><meta charset="utf-8"><title>booting</title></head>
<body style="font:16px monospace;background:#111;color:#eee">
<textarea id="t" rows="4" cols="60" autofocus style="font:16px monospace;width:90%"></textarea>
<pre id="out"></pre>
<script>
const p = new URLSearchParams(location.search);
const t = document.getElementById('t');
t.value = p.get('text') ?? '';
const caret = parseInt(p.get('caret') ?? t.value.length, 10);
function report() {
  // Chromium trims and collapses whitespace in document.title, so delimit the
  // payload with brackets and escape newlines before round-tripping.
  const v = t.value.replace(/\n/g, '\\n');
  const s = `CARET=${t.selectionStart},${t.selectionEnd}|TEXT=[${v}]`;
  document.title = s;
  document.getElementById('out').textContent = s;
}
window.addEventListener('load', () => {
  t.focus(); t.setSelectionRange(caret, caret); report();
});
setInterval(report, 50);
</script></body></html>
HTMLEOF

# ===================== launch cage + chromium (contained) ====================
# cage's wayland backend (a nested window) rather than headless: the headless
# backend has no seat keyboard, which breaks wl-clipboard and so the omnibox
# readback. The nested window is still a separate compositor with its own
# socket, so containment is unaffected.
setsid --fork cage -- /bin/sh -c "
  echo \"\$WAYLAND_DISPLAY\" > '$ENVFILE'
  exec chromium --ozone-platform=wayland \
    --user-data-dir='$WORKDIR/profile' \
    --remote-debugging-port=$PORT \
    --no-first-run --no-default-browser-check \
    --disable-extensions --disable-sync \
    about:blank
" >"$CAGELOG" 2>&1 </dev/null
CAGE_PID=""
(( SHOW )) && tail -f "$CAGELOG" >&2 &

for _ in {1..60}; do [[ -s "$ENVFILE" ]] && break; sleep 0.5; done
WD=$(cat "$ENVFILE" 2>/dev/null)
[[ -n "$WD" ]] || { echo "cage never started; see $CAGELOG" >&2; KEEP=1; exit 1; }
[[ "$WD" != "${WAYLAND_DISPLAY:-}" ]] || { echo "refusing to run: nested display == host display" >&2; exit 1; }

for _ in {1..80}; do curl -sf "http://127.0.0.1:$PORT/json/version" >/dev/null && break; sleep 0.5; done
curl -sf "http://127.0.0.1:$PORT/json/version" >/dev/null || {
  echo "chromium never came up inside cage; see $CAGELOG" >&2; KEEP=1; exit 1; }

echo
echo "  contained in cage: nested display [$WD], host is [${WAYLAND_DISPLAY:-none}]"

# ============================== web content ==================================
page_title() {
  curl -s "http://127.0.0.1:$PORT/json" \
    | jq -r '[.[] | select(.type=="page" and (.url|startswith("file://")))][0].title // ""'
}
close_pages() {
  for id in $(curl -s "http://127.0.0.1:$PORT/json" \
      | jq -r '.[]|select(.type=="page" and (.url|startswith("file://")))|.id'); do
    curl -s "http://127.0.0.1:$PORT/json/close/$id" >/dev/null
  done
}
wait_title() { local w=$1 n=$2; for _ in $(seq 1 "$n"); do
  [[ "$(page_title)" == "$w" ]] && return 0; sleep 0.2; done; return 1; }

report() {
  if [[ $1 == ok ]]; then printf '  %sPASS%s  %-24s %s\n' "$G" "$N" "$2" "$3"; PASS=$((PASS+1))
  else                    printf '  %sFAIL%s  %-24s %s\n' "$R" "$N" "$2" "$3"; FAIL=$((FAIL+1)); fi
}
esc_nl() { local s=${1//$'\n'/\\n}; printf '%s' "$s"; }

# web_case <name> <text> <caret> <want-caret> <want-text> -- <wtype args...>
web_case() {
  local name=$1 text=$2 caret=$3 expc=$4 expt=$5; shift 6
  local start="CARET=$caret,$caret|TEXT=[$(esc_nl "$text")]"
  local want="CARET=$expc,$expc|TEXT=[$(esc_nl "$expt")]"
  local last=""
  for attempt in $(seq 1 "$ATTEMPTS"); do
    close_pages
    curl -s -X PUT "http://127.0.0.1:$PORT/json/new?$(enc \
         "file://$HTML?text=$(enc "$text")&caret=$caret")" >/dev/null
    wait_title "$start" 50 || { last="page never reached start state"; continue; }
    key "$@"
    if wait_title "$want" 12; then
      local note=""; (( attempt > 1 )) && note="  ${Y}(retry $attempt)${N}"
      report ok "$name" "$want$note"; return
    fi
    last="got: $(page_title)"
  done
  report no "$name" "$last  want: $want"
}

# ================================ omnibox ====================================
omnibox_read() {
  clip_clear; sleep 0.2
  # Cannot use C-a to select-all here: under the Emacs theme C-a is
  # "move to line start". Home / shift-End is key-theme independent.
  key -k Home; sleep 0.15
  key -M shift -k End -m shift; sleep 0.2
  key -M ctrl -k c -m ctrl
  for _ in {1..15}; do
    local v; v=$(clip); [[ -n "$v" ]] && { printf '%s' "$v"; return; }
    sleep 0.2
  done
  printf ''
}

# omnibox_case <name> <typed> <want> -- <wtype args...>
omnibox_case() {
  local name=$1 typed=$2 want=$3; shift 4
  local last=""
  for attempt in $(seq 1 "$ATTEMPTS"); do
    key -M ctrl -k l -m ctrl; sleep 0.4      # focus omnibox + select all
    key -k Delete;            sleep 0.25
    key -- "$typed";          sleep 0.6
    local seeded; seeded=$(omnibox_read)
    if [[ "$seeded" != "$typed" ]]; then
      last="could not seed omnibox (got: [$seeded])"; key -k Escape; continue
    fi
    key -k End; sleep 0.2                    # drop selection, caret to end
    key "$@"; sleep 0.5
    local got; got=$(omnibox_read)
    key -k Escape; sleep 0.2
    if [[ "$got" == "$want" ]]; then
      local note=""; (( attempt > 1 )) && note="  ${Y}(retry $attempt)${N}"
      report ok "$name" "[$got]$note"; return
    fi
    last="got: [$got]"
  done
  report no "$name" "$last  want: [$want]"
}

# ================================== run ======================================
echo
echo "=== web page textarea ==="
web_case "C-b  back char"     "alpha beta" 10 9  "alpha beta" -- -M ctrl -k b -m ctrl
web_case "C-f  forward char"  "alpha beta" 0  1  "alpha beta" -- -M ctrl -k f -m ctrl
web_case "M-b  back word"     "alpha beta" 10 6  "alpha beta" -- -M alt  -k b -m alt
web_case "M-f  forward word"  "alpha beta" 0  5  "alpha beta" -- -M alt  -k f -m alt
web_case "C-d  delete char"   "alpha beta" 5  5  "alphabeta"  -- -M ctrl -k d -m ctrl
web_case "M-d  delete word"   "alpha beta" 6  6  "alpha "     -- -M alt  -k d -m alt
web_case "C-a  line start"    "alpha beta" 10 0  "alpha beta" -- -M ctrl -k a -m ctrl
web_case "C-e  line end"      "alpha beta" 0  10 "alpha beta" -- -M ctrl -k e -m ctrl
web_case "C-k  kill to EOL"   "alpha beta" 5  5  "alpha"      -- -M ctrl -k k -m ctrl
web_case "C-h  del back char" "alpha beta" 5  4  "alph beta"  -- -M ctrl -k h -m ctrl
web_case "C-p  previous line" $'one\ntwo'  7  3  $'one\ntwo'  -- -M ctrl -k p -m ctrl
web_case "C-n  next line"     $'one\ntwo'  0  4  $'one\ntwo'  -- -M ctrl -k n -m ctrl

echo
echo "=== omnibox (address bar) ==="
omnibox_case "C-b C-b then C-d"  "alpha beta" "alpha bea" -- -M ctrl -k b -m ctrl -M ctrl -k b -m ctrl -M ctrl -k d -m ctrl
omnibox_case "C-a then C-d"      "alpha beta" "lpha beta" -- -M ctrl -k a -m ctrl -M ctrl -k d -m ctrl
omnibox_case "C-a C-f C-f + C-d" "alpha beta" "alha beta" -- -M ctrl -k a -m ctrl -M ctrl -k f -m ctrl -M ctrl -k f -m ctrl -M ctrl -k d -m ctrl
omnibox_case "M-b then C-d"      "alpha beta" "alpha eta" -- -M alt  -k b -m alt  -M ctrl -k d -m ctrl
omnibox_case "M-b then M-d"      "alpha beta" "alpha "    -- -M alt  -k b -m alt  -M alt  -k d -m alt
# Alt+F is Chromium's app-menu accelerator, so it is the one binding at real
# risk of being shadowed in native UI. Seek to the start first, otherwise a
# forward motion at end-of-line is a no-op and the case proves nothing.
omnibox_case "M-f then C-d"      "alpha beta" "alphabeta" -- -k Home -M alt -k f -m alt -M ctrl -k d -m ctrl
omnibox_case "M-d at line start" "alpha beta" " beta"     -- -k Home -M alt -k d -m alt

echo
printf '=== passed %d, failed %d ===\n' "$PASS" "$FAIL"
(( FAIL == 0 ))

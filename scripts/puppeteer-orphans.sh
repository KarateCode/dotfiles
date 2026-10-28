#!/bin/bash
# Report or kill leaked Puppeteer Chrome browsers.
#
# A browser is an orphan when its parent is systemd/init -- the launching node
# process died without reaping it. Browsers with a live parent are an active
# test run and are never touched.
#
#   (no args)  report
#   kill       terminate orphans and remove their /tmp profile dirs
set -uo pipefail

orphan_pids() {
  ps -eo pid,ppid,args | grep '[.]cache/puppeteer/chrome' | grep -v -- '--type=' |
    while read -r pid ppid _; do
      case "$(ps -o comm= -p "$ppid" 2>/dev/null | tr -d ' ')" in
        systemd | init | "") printf '%s\n' "$pid" ;;
      esac
    done
}

total_rss_mb() { # browser pids on stdin; includes their children
  local tot=0 p c r
  while read -r p; do
    for c in "$p" $(pgrep -P "$p" 2>/dev/null); do
      r=$(ps -o rss= -p "$c" 2>/dev/null | tr -d ' ')
      tot=$((tot + ${r:-0}))
    done
  done
  echo $((tot / 1024))
}

pids=$(orphan_pids)
count=$([ -n "$pids" ] && printf '%s\n' "$pids" | wc -l || echo 0)

if [[ ${1:-} != "kill" ]]; then
  live=$(ps -eo pid,ppid,args | grep '[.]cache/puppeteer/chrome' | grep -vc -- '--type=' || true)
  echo "orphaned puppeteer browsers: $count"
  if ((count > 0)); then
    echo "  memory held : $(printf '%s\n' "$pids" | total_rss_mb) MB"
    echo "  oldest      : $(ps -o etime= -p "$(printf '%s\n' "$pids" | head -1)" 2>/dev/null | tr -d ' ')"
  fi
  echo "  /tmp profiles: $(ls -d /tmp/puppeteer_dev_chrome_profile-* 2>/dev/null | wc -l) dirs, $(du -ch /tmp/puppeteer_dev_chrome_profile-* 2>/dev/null | tail -1 | cut -f1)"
  echo "  live (in-use): $((live - count)) browser(s) left alone"
  exit 0
fi

if ((count == 0)); then echo "no orphans"; exit 0; fi

# Capture profile dirs before the processes vanish.
profiles=$(for p in $pids; do
  tr '\0' '\n' <"/proc/$p/cmdline" 2>/dev/null | sed -n 's/^--user-data-dir=//p'
done | sort -u)

freed=$(printf '%s\n' "$pids" | total_rss_mb)
# shellcheck disable=SC2086
kill $pids 2>/dev/null
sleep 2
survivors=$(for p in $pids; do kill -0 "$p" 2>/dev/null && printf '%s ' "$p"; done)
# shellcheck disable=SC2086
[[ -n $survivors ]] && kill -9 $survivors 2>/dev/null

removed=0
while read -r d; do
  [[ $d == /tmp/puppeteer_dev_chrome_profile-* && -d $d ]] || continue
  rm -rf -- "$d" && removed=$((removed + 1))
done <<<"$profiles"

echo "killed $count orphan browser(s), freed ~${freed} MB"
echo "removed $removed profile dir(s)"

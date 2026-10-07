#!/bin/zsh

set -u

dir="${DOWNLOADS_DIR:-$HOME/Downloads}"

note() {
    notify-send -a downloads -u "${3:-normal}" "$1" "${2:-}" 2>/dev/null \
        || print -u2 -- "$1: ${2:-}"
}

if [[ ! -d "$dir" ]]; then
    note "No downloads folder" "$dir does not exist" critical
    exit 1
fi

# Newest first, regular files only, no error when empty.
candidates=( $dir/*(om.N) )

target=""
for f in $candidates; do
    case "${f:t}" in
        *.crdownload|*.part|*.partial|*.download|*.tmp|*.opdownload) continue ;;
    esac
    target="$f"
    break
done

if [[ -z "$target" ]]; then
    if (( ${#candidates} )); then
        note "Nothing to open" "Newest item in ${dir:t} is still downloading"
    else
        note "Nothing to open" "No files in $dir"
    fi
    exit 1
fi

if whence uwsm-app >/dev/null; then
    setsid uwsm-app -- xdg-open "$target" >/dev/null 2>&1 &
else
    setsid xdg-open "$target" >/dev/null 2>&1 &
fi
disown 2>/dev/null

[[ "${OPEN_RECENT_NOTIFY:-0}" == "1" ]] && note "Opening" "${target:t}" low

exit 0

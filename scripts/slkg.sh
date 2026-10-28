#!/bin/bash

exec setsid -f uwsm-app -- ghostty --background-opacity-cells=true -e slk >/dev/null 2>&1

#!/bin/bash

git ls-files -m | grep -m 1 "" | xargs emacsclient -nw -a ''

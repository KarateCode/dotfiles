#!/bin/bash

git ls-files -m | grep -m 1 "" | xargs git checkout
git status

#!/bin/bash

find . -type f |
    grep -v ".git" |
    grep -v "./client/bower_components" |
    grep -v "./node_modules" |
    grep -v "./client/src/fonts" |
    grep -v "./client/vendor" |
    grep -v "./client/GlyphishFont2" |
    grep -v "./legacy" |
    grep -v "./utilities" |
    grep -v ".client/dist" |
    xargs grep -n $1

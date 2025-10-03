#!/bin/bash

git status | grep -m 1 "both modified" | sed "s/	both modified:   //g" | xargs sub
git status | grep -m 1 "deleted:" | sed "s/    deleted:   //g" | xargs sub

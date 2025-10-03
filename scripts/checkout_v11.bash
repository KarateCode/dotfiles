#!/bin/bash

cd /Users/michael/appropos/awt
git checkout v11
nvm use
mv node_modules ../node_modules_dev
mv ../node_modules_v11 ./node_modules

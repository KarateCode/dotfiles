#!/bin/bash

cd /Users/michael/appropos/awt
git checkout develop
nvm use
mv node_modules ../node_modules_v11
mv ../node_modules_dev ./node_modules

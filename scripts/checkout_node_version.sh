#!/bin/zsh

source ~/.nvm/nvm.sh
PROJECTS_PATH=/Users/michael/appropos
ENVOY_FOLDER=awt

# Get to the correct starting point
cd $PROJECTS_PATH
# remove old symlink
rm $ENVOY_FOLDER
# point symlink to proper project
ln -s $1 $ENVOY_FOLDER
# enter envoy project
cd $ENVOY_FOLDER
# make sure we're on the correct version of node
nvm use

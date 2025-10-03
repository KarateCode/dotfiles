#!/bin/bash

# Remember current feature branch
FEATURE_BRANCH=`git symbolic-ref --short HEAD`
TEST_BUCKET=`git branch | grep "test-bucket" | sed "s/^.\{2\}//g"`
echo $FEATURE_BRANCH
echo $TEST_BUCKET

# check test-bucket branch
git checkout $TEST_BUCKET

git pull origin $TEST_BUCKET

git merge $FEATURE_BRANCH

git push origin $FEATURE_BRANCH
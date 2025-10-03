#!/bin/bash

# Set up variables
OLD_TEST_BUCKET=`git branch | grep "test-bucket" | sed "s/^.\{2\}//g"`
TEST_BUCKET_NUMBER=`git branch | grep "test-bucket" | sed "s/^.\{2\}test-bucket-//g"`
let "NEW_NUMBER = $TEST_BUCKET_NUMBER + 1"
NEW_TEST_BUCKET="test-bucket-$NEW_NUMBER"

echo "Refreshing develop"
git checkout develop
git pull origin develop

echo "Deleting old test-bucket $OLD_TEST_BUCKET"
git branch -D $OLD_TEST_BUCKET
git push origin :$OLD_TEST_BUCKET

echo "Pulling origin with prune"
git remote update origin --prune
echo "Creating new test-bucket"
git checkout -b $NEW_TEST_BUCKET
git push origin $NEW_TEST_BUCKET

echo ""
echo "⚡️  Done! ⚡️"
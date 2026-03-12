#!/bin/zsh

# Need checking for presence of NAMING_PREFIX

echo "  Session passed: $1"
userId=$(mongosh $NAMING_PREFIX --quiet --eval "JSON.stringify(db.AuthSession.findOne({_id: '$1'}))" | jq -r ".user")

echo "  userId: $userId"
taskId=$(mongosh $NAMING_PREFIX --quiet --eval "JSON.stringify(db.Task.find({userId: ObjectId('$userId')}).toArray())" | jq -r 'max_by(.createDate) | ._id')
echo "  taskId: $taskId"

curl -OJ -H 'sec-ch-ua: "Not:A-Brand";v="99", "Google Chrome";v="145", "Chromium";v="145"' \
     -H 'sec-ch-ua-mobile: ?0' \
     -H 'sec-ch-ua-platform: "macOS"' \
     -H 'upgrade-insecure-requests: 1' \
     -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
     -H 'sec-fetch-site: same-origin' \
     -H 'sec-fetch-mode: navigate' \
     -H 'sec-fetch-user: ?1' \
     -H 'sec-fetch-dest: document' \
     -H 'referer: https://seedbrand.awt.loc/envoy/downloads' \
     -H 'accept-language: en-US,en;q=0.9' \
     -H "cookie: envoy_cookie-consent=true; ENVOY_IS_MAIN_NAV_ACTIVE=true; envoy_language=en-US; ENVOY_PRODUCT_VIEW_MODE=GRID; ENVOY_LAST_SELECTED_LIST=69a1b93de0341c5496d07452; envoy_SESSION=$1" \
     "http://seedbrand.awt.loc/api/downloads/$taskId"

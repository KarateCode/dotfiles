#!/bin/zsh

Yellow='\033[0;33m'
Red='\033[0;31m'
Color_Off='\033[0m'

if [[ -z $1 ]]; then
	echo "You forgot to give the EP number value. For example: "
	echo "	cof 594"
	exit -1
fi

FEATURE=`git branch | grep "EP-$1" | sed "s/^.\{2\}//g"`

# If we have it locally, check it out:
if [[ $FEATURE ]]; then
	git checkout $FEATURE
	exit 0
fi

# if not, check origin for the feature branch
echo -e "${Yellow}Branch was not found locally, checking origin...${Color_Off}"
git remote update
REMOTE_FEATURE=`git branch -r | grep "EP-$1" | sed "s/^.\{2\}origin\///g"`
if [[ $REMOTE_FEATURE ]]; then
	git fetch
	git checkout $REMOTE_FEATURE
	exit 0
fi

echo -e "${Red}Feature Branch EP-$1 not found ${Color_Off}"

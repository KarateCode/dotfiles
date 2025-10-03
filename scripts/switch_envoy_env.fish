#!/usr/local/bin/fish

# one based array. weird....
echo "/Users/michael/appropos/$argv[1]"

cd "/Users/michael/appropos"
unlink awt
ln -s $argv[1] awt
cd awt
bass source ~/.nvm/nvm.sh --no-use ';' nvm use

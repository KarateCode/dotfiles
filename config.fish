# You will need to add:
#   /usr/local/bin/fish
# to /etc/shells.

# Then run:
#   chsh -s /usr/local/bin/fish
# to make fish your default shell.

# export NVM_DIR="/Users/michael/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
# bash npm.bash
export ENVOY_PATH=/Users/michael/appropos/awt

source ~/.config/fish/alias.fish
# rvm default

function fish_prompt
	if not set -q __git_cb
		set __git_cb (git branch ^/dev/null | grep \* | sed 's/* //')
	end

	set_color brred
	echo ""
	echo -n (prompt_hostname)" "
	set_color brgreen
	echo -n (prompt_pwd)" "
	set_color brwhite
	echo $__git_cb
	echo -n '🎄  '

	# set_color bryellow
	# echo ""
	# echo -n (prompt_hostname)" "
	# set_color brgreen
	# echo -n (prompt_pwd)" "
	# set_color brmagenta
	# echo $__git_cb
	# echo -n '🎃  '

	set_color normal
end

function fish_right_prompt
	echo "❄️  ⛄ ️ ❄️ "
end

# function fish_right_prompt
# 	echo "🍁 💀 🍁"
# end
# echo '                     __'
# echo '                   /  /'
# echo '                  /  ('
# echo '          ____   /   \  ,____'
# echo '      ,_--    `\/_____\/     --_'
# echo '    ,/         ,/ / \ \         `\\'
# echo '   /         ,/  /   \ `\         `\\'
# echo '  /       . /    /   \   `\ .       \\'
# echo ' /       / \    /     \    / \       \\'
# echo ' /      /___\   /     \   /___\      \\'
# echo '/        /     /       \     \        \\'
# echo '/       /      / _____ \      \       \\'
# echo '(       (      ( \   / )      )       )'
# echo '\       \      \  \ /  /      /       /'
# echo ' \       \     \   `   /     /       /'
# echo ' \     __ \   . \  .  / .   /,__     /'
# echo '  \    \ `\  / \  / \  / \  /  /    /'
# echo '   \    \  \/   \/   \/   \/  /   ,/'
# echo '    `\_  \___________________/ ,_/'
# echo '       `\_____\___\_/___/_____/'

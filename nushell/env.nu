# Nushell Environment Config File Documentation
#
# version = "0.111.0"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.

# To pretty-print the in-shell documentation for Nushell's various configuration
# settings, you can run:
# config nu --doc | nu-highlight | less -R

# Use nushell-specific starship config
$env.STARSHIP_CONFIG = ($env.HOME | path join "dotfiles/starship/starship-nushell.toml")

# Initialize starship prompt
mkdir ~/.cache/starship
do { starship init nu } | complete | get stdout | save -f ~/.cache/starship/init.nu

# Node is managed by mise. Omarchy already puts ~/.local/share/mise/shims on
# PATH (/etc/security/pam_env.conf), and the shims resolve the version per
# directory, so no shell integration is needed here. Per-project versions come
# from .nvmrc / .node-version via idiomatic_version_file_enable_tools in
# ~/.config/mise/config.toml. (fnm was removed.)

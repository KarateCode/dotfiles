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
$env.STARSHIP_CONFIG = ($env.HOME | path join "dotfiles/starship-nushell.toml")

# Initialize starship prompt
mkdir ~/.cache/starship
do { starship init nu } | complete | get stdout | save -f ~/.cache/starship/init.nu

# fnm (Fast Node Manager) - replaces nvm
# Generate fnm environment variables and load them
let fnm_env = (^fnm env --json | from json)
load-env {
    FNM_MULTISHELL_PATH: $fnm_env.FNM_MULTISHELL_PATH
    FNM_DIR: $fnm_env.FNM_DIR
    FNM_LOGLEVEL: $fnm_env.FNM_LOGLEVEL
    FNM_NODE_DIST_MIRROR: $fnm_env.FNM_NODE_DIST_MIRROR
    FNM_COREPACK_ENABLED: $fnm_env.FNM_COREPACK_ENABLED
    FNM_ARCH: $fnm_env.FNM_ARCH
    FNM_VERSION_FILE_STRATEGY: $fnm_env.FNM_VERSION_FILE_STRATEGY
    FNM_RESOLVE_ENGINES: $fnm_env.FNM_RESOLVE_ENGINES
}
# Add fnm's bin directory to PATH (must come before /opt/homebrew/bin)
$env.PATH = ($env.PATH | prepend ($fnm_env.FNM_MULTISHELL_PATH | path join "bin"))

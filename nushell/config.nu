
use std "path add"
path add "~/.cargo/bin"

$env.config.show_banner = false
# $env.config.history.isolation = true

# source_sh_exports must come before alias.nu (alias.nu uses load-sh-exports)
source ~/dotfiles/scripts/source_sh_exports.nu
source ~/dotfiles/scripts/mongo_shell_inline.nu
source ~/dotfiles/nushell/alias.nu

# Initialize starship prompt
source ~/.cache/starship/init.nu


source ~/dotfiles/nushell/alias.nu

use std "path add"
path add "~/.cargo/bin"

$env.config.show_banner = false
use ~/dotfiles/scripts/source_sh_exports.nu *

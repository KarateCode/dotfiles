
use std "path add"
path add "~/.cargo/bin"

$env.config.show_banner = false
# $env.config.history.isolation = true

# source_sh_exports must come before alias.nu (alias.nu uses load-sh-exports)
source ~/dotfiles/scripts/source_sh_exports.nu
source ~/dotfiles/scripts/mongo_shell_inline.nu
source ~/dotfiles/scripts/editor.nu
source ~/dotfiles/scripts/mongo_select.nu
source ~/dotfiles/scripts/delete_many.nu
source ~/dotfiles/scripts/update_many.nu
source ~/dotfiles/scripts/rebase_on_develop.nu
source ~/dotfiles/nushell/alias.nu

# Snippets engine - abbreviation expansion with placeholder jumping
source ~/dotfiles/nushell/snippets/engine.nu
source ~/dotfiles/nushell/snippets/keybindings.nu
$env.config.keybindings = ($env.config.keybindings | append (get-snippet-keybindings))

# Initialize starship prompt
source ~/.cache/starship/init.nu

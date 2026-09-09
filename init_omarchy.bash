sudo pacman -S nushell
sudo pacman -S tmux

echo "source ~/dotfiles/nushell/config.nu" >> ~/.config/nushell/config.nu
# back up and symlink tmux conf

sudo pacman -S starship
ln -s ~/dotfiles/starship/init.nu ~/.cache/starship/init.nu

sudo pacman -S zsh
sudo pacman -S herdr

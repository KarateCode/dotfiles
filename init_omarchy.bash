sudo pacman -S nushell
sudo pacman -S tmux

echo "source ~/dotfiles/nushell/config.nu" >> ~/.config/nushell/config.nu
# back up and symlink tmux conf

sudo pacman -S starship
ln -s ~/dotfiles/starship/init.nu ~/.cache/starship/init.nu

sudo pacman -S zsh
sudo pacman -S herdr

curl -fsSL https://fnm.vercel.app/install | bash

sudo pacman -S go
go install github.com/ankitpokhrel/jira-cli/cmd/jira@latest
# add ~/go/bin to $PATH

curl -L -o lazyvpn https://github.com/blank-query/lazyVPN-for-Omarchy/releases/latest/download/lazyvpn
chmod +x lazyvpn
./lazyvpn install

yay -S slack-desktop

# adjust user and docker permissions
sudo usermod -aG docker $USER
newgrp docker

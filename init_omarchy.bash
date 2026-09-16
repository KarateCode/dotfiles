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
npm run nginx-local

# creates a yml file based on an existing container:
# docker run --rm -v /var/run/docker.sock:/var/run/docker.sock red5d/docker-autocompose <container-name-or-id>

# runs the yml file automatically if you're cd'd into the directory
docker compose up -d
# docker ps -a # shows all iamges, even if not running

# op signin
# op whoami

omarchy pkg add aws-cli-v2
# aws configure sso
# copy ~/.aws/config from old machine
# can test with:
# aws sts get-caller-identity

echo '127.0.0.1 awt.loc' | sudo tee -a /etc/hosts
sudo ufw allow from 172.16.0.0/12 to any port 3000 proto tcp comment 'docker to node backend'
printf '127.0.0.1 seedbrand.awt.loc seedclient.awt.loc sodbrand.awt.loc sodclient.awt.loc\n' | sudo tee -a /etc/hosts

yay -S spotify-player

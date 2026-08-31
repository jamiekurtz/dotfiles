#!/bin/bash

set -euo pipefail

# refresh
sudo apt update

# base packages for sway on Debian
sudo apt install sway swayidle swaylock swaybg foot \
  i3status wmenu wofi xwayland dex mako-notifier \
  pipewire pipewire-pulse wireplumber pulseaudio-utils \
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
  grim slurp swappy jq wl-clipboard brightnessctl pulsemixer \
  network-manager network-manager-gnome mate-polkit \
  thermald fonts-dejavu curl firefox-esr \
  zip unzip tree

# other stuff
sudo apt install -y pipx ranger git-flow golang bash-completion gpg make kdiff3

# neovim and related
sudo apt remove neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo apt install -y ripgrep

# install nerd fonts
mkdir -p ~/.local/share/fonts/JetBrainsMonoNF
cd ~/.local/share/fonts/JetBrainsMonoNF
wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip JetBrainsMono.zip
rm JetBrainsMono.zip
fc-cache -fv

# install lazygit
go install github.com/jesseduffield/lazygit@latest

# install lazyvim
git clone https://github.com/LazyVim/starter.git ~/.config/nvim
rm -rf ~/.config/nvim/.git

# install resilio-sync
wget -P ~/Downloads https://download-cdn.resilio.com/stable/linux/x64/0/resilio-sync_x64.tar.gz
mkdir -p ~/MyApps/resilio-sync
tar -xzf ~/Downloads/resilio-sync_x64.tar.gz -C ~/MyApps/resilio-sync/

# install 1password
curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list
sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
sudo apt update && sudo apt install 1password

# install claude code
curl -fsSL https://claude.ai/install.sh | bash

# install AWS CLI
pushd ~/Downloads
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
popd

# install AWS VPN Client
curl https://d20adtppz83p9s.cloudfront.net/GTK/latest/awsvpnclient_amd64.deb -o ~/Downloads/awsvpnclient_amd64.debawsvpnclient_amd64.deb
sudo dpkg -i ~/Downloads/awsvpnclient_amd64.deb
sudo systemctl --now enable awsvpnclient

# *****************************
# install docker engine and docker compose

# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update && apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

# *****************************
# *****  install nodejs  ******

# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.7/install.sh | bash

# in lieu of restarting the shell
\. "$HOME/.nvm/nvm.sh"

# Download and install Node.js:
nvm install 24

# Verify the Node.js version:
node -v # Should print "v24.20.0".

# Verify npm version:
npm -v # Should print "11.19.0".

# *****************************
# *****  install zulu 21  ******

sudo apt install -y gnupg ca-certificates curl

curl -s https://repos.azul.com/azul-repo.key |
  sudo gpg --dearmor -o /usr/share/keyrings/azul.gpg

echo "deb [signed-by=/usr/share/keyrings/azul.gpg] https://repos.azul.com/zulu/deb stable main" |
  sudo tee /etc/apt/sources.list.d/zulu.list

sudo chmod 644 /usr/share/keyrings/azul.gpg

sudo apt update
sudo apt install -y zulu21-jdk

ln -sf /usr/lib/jvm/zulu21-ca-amd64 /usr/lib/jvm/default

# install dbeaver
wget -P ~/Downloads https://dbeaver.io/files/dbeaver-ce-latest-linux-x86_64.deb
sudo apt install ~/Downloads/dbeaver-ce-26.1.5-linux-x86_64.deb

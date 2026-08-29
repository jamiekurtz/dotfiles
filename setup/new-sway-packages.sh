#!/bin/bash

set -euo pipefail

# refresh
sudo apt update

# base packages for sway on Debian
sudo apt install sway swayidle swaylock swaybg foot \
  i3status wmenu wofi xwayland dex mako-notifier \
  pipewire pipewire-pulse wireplumber \
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
  grim slurp swappy jq wl-clipboard brightnessctl pulsemixer \
  network-manager network-manager-gnome mate-polkit \
  thermald fonts-dejavu curl firefox-esr

# other stuff
sudo apt install -y ranger git-flow golang bash-completion

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

# install lazyvim; copy my nvim stuff
git clone https://github.com/LazyVim/starter.git ~/.config/nvim
rm -rf ~/.config/nvim/.git

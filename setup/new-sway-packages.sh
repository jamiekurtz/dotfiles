#!/bin/bash

# refresh
sudo apt update

# base packages for sway on Debian
sudo apt install sway swayidle swaylock swaybg foot \
  i3status wmenu wofi xwayland dex mako-notifier \
  pipewire pipewire-pulse wireplumber \
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
  grim slurp swappy jq wl-clipboard brightnessctl pulsemixer \
  network-manager network-manager-gnome mate-polkit \
  thermald fonts-dejavu

# other stuff
sudo apt install -y ranger git-flow golang bash-completion

# neovim and related
sudo apt remove neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo apt install -y ripgrep

# install nerd fonts
mkdir -p ~/MyApps
cd ~/MyApps
git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git
cd nerd-fonts
./install.sh JetBrainsMono

# install lazygit
go install github.com/jesseduffield/lazygit@latest

# install lazyvim; copy my nvim stuff
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

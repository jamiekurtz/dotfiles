#!/bin/bash
# Everything that needs a display. Desktop profile only.
set -euo pipefail

sudo apt update

# --- sway session --------------------------------------------------------
sudo apt install -y \
  sway swayidle swaylock swaybg foot \
  i3status wmenu wofi xwayland dex mako-notifier \
  pipewire pipewire-pulse wireplumber pulseaudio-utils \
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
  grim slurp swappy wl-clipboard brightnessctl pulsemixer \
  network-manager network-manager-gnome mate-polkit \
  thermald fonts-dejavu firefox-esr thunar gsimplecal \
  kdiff3 ranger

# needed for bin/swaycwd
sudo apt install -y jq gron

# --- JetBrains Mono Nerd Font --------------------------------------------
# Fonts belong on the machine that draws the pixels, which is this one.
# The EC2 box never needs them: neovim there emits the codepoints and this
# terminal resolves the glyphs.
mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNF"
(
  cd "$HOME/.local/share/fonts/JetBrainsMonoNF"
  wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  unzip -oq JetBrainsMono.zip
  rm JetBrainsMono.zip
)
fc-cache -f
fc-match "JetBrainsMono Nerd Font Mono"

# --- 1password -----------------------------------------------------------
curl -sS https://downloads.1password.com/linux/keys/1password.asc |
  sudo gpg --dearmor --yes --output /usr/share/keyrings/1password-archive-keyring.gpg
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' |
  sudo tee /etc/apt/sources.list.d/1password.list
sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol |
  sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol >/dev/null
sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
curl -sS https://downloads.1password.com/linux/keys/1password.asc |
  sudo gpg --dearmor --yes --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
sudo apt update
sudo apt install -y 1password

# --- resilio sync --------------------------------------------------------
mkdir -p "$HOME/Downloads" "$HOME/MyApps/resilio-sync"
wget -qO "$HOME/Downloads/resilio-sync_x64.tar.gz" \
  https://download-cdn.resilio.com/stable/linux/x64/0/resilio-sync_x64.tar.gz
tar -xzf "$HOME/Downloads/resilio-sync_x64.tar.gz" -C "$HOME/MyApps/resilio-sync/"
rm "$HOME/Downloads/resilio-sync_x64.tar.gz"

# --- aws vpn client ------------------------------------------------------
# NOTE: the original script doubled the filename here, so the dpkg below could
# never find the file.
curl -fsSL https://d20adtppz83p9s.cloudfront.net/GTK/latest/awsvpnclient_amd64.deb \
  -o "$HOME/Downloads/awsvpnclient_amd64.deb"
sudo dpkg -i "$HOME/Downloads/awsvpnclient_amd64.deb" || sudo apt install -yf
sudo systemctl --now enable awsvpnclient

# --- dbeaver -------------------------------------------------------------
wget -qO "$HOME/Downloads/dbeaver-ce.deb" \
  https://dbeaver.io/files/dbeaver-ce-latest-linux-x86_64.deb
sudo apt install -y "$HOME/Downloads/dbeaver-ce.deb"

# --- p14 laptop firmware -------------------------------------------------
if [ "$(hostname)" = "shadowlt" ]; then
  sudo apt install -y firmware-atheros firmware-misc-nonfree
  echo "firmware installed -- reboot when convenient."
fi

echo
echo "desktop packages installed. See docs/desktop-notes.md for the"
echo "AWS Client VPN DNS fix, power management, and Slack screen sharing."

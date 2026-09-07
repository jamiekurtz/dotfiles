#!/bin/bash
# Headless server profile only. Everything else comes from common-packages.sh.
set -euo pipefail

sudo apt update

# mosh survives a laptop lid close far better than plain ssh.
#
# foot-terminfo: ssh forwards the client's $TERM, and the desktop profile's
# terminal is foot, so a box without foot's terminfo entry greets every less,
# man and git log with "WARNING: terminal is not fully functional". The
# terminfo is packaged separately from foot itself precisely so it can be
# installed on remote hosts. ncurses-term covers the same problem for the
# other terminals worth sshing in from (tmux-256color, alacritty, kitty).
sudo apt install -y mosh locales foot-terminfo ncurses-term

# Back the UTF-8 export in shell/profile.server with a generated locale.
# Without this, LANG=en_US.UTF-8 is set but not valid, and glyphs still break.
sudo sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen

# --- tailscale -----------------------------------------------------------
# Network layer only. `tailscale up` is a separate, interactive step:
#   ./setup/server-tailscale.sh
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi

echo
echo "server packages installed. Next:"
echo "  ./setup/server-tailscale.sh"

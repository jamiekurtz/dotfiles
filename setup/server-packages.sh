#!/bin/bash
# Headless server profile only. Everything else comes from common-packages.sh.
set -euo pipefail

sudo apt update

# mosh survives a laptop lid close far better than plain ssh.
sudo apt install -y mosh locales

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

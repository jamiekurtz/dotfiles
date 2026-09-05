#!/bin/bash
# Terminal toolchain. Installed on both the desktop and server profiles.
set -euo pipefail

sudo apt update

sudo apt install -y \
  git git-flow tmux curl wget jq gron tree zip unzip ripgrep btop \
  make gpg bash-completion pipx golang ca-certificates gnupg ranger

# --- neovim (upstream release, Debian's is too old for LazyVim) -----------
sudo apt remove -y neovim || true
tmpdir=$(mktemp -d)
curl -Lo "$tmpdir/nvim.tar.gz" \
  https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf "$tmpdir/nvim.tar.gz"
rm -rf "$tmpdir"

# LazyVim starter, only if there is no nvim config yet -- bootstrap.sh links
# our own init.lua into it afterwards.
if [ ! -d "$HOME/.config/nvim/lua/config" ]; then
  git clone https://github.com/LazyVim/starter.git "$HOME/.config/nvim-lazyvim"
  rm -rf "$HOME/.config/nvim-lazyvim/.git"
  mkdir -p "$HOME/.config/nvim"
  cp -rn "$HOME/.config/nvim-lazyvim/." "$HOME/.config/nvim/"
  rm -rf "$HOME/.config/nvim-lazyvim"
fi

# --- lazygit / lazydocker ------------------------------------------------
# `ld` has been aliased to lazydocker for a long time with nothing installing
# it; this is where it comes from now.
go install github.com/jesseduffield/lazygit@latest
go install github.com/jesseduffield/lazydocker@latest

# --- node ----------------------------------------------------------------
if [ ! -d "$HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.7/install.sh | bash
fi
# nvm.sh references variables that may be unset before it has initialized
# them; under `set -u` that can be treated as fatal even on success, so relax
# -u only around the source, not around the nvm commands that follow.
set +u
# shellcheck disable=SC1091
. "$HOME/.nvm/nvm.sh"
set -u
nvm install 24

# --- zulu 21 jdk ---------------------------------------------------------
curl -s https://repos.azul.com/azul-repo.key |
  sudo gpg --dearmor --yes -o /usr/share/keyrings/azul.gpg
sudo chmod 644 /usr/share/keyrings/azul.gpg
echo "deb [signed-by=/usr/share/keyrings/azul.gpg] https://repos.azul.com/zulu/deb stable main" |
  sudo tee /etc/apt/sources.list.d/zulu.list
sudo apt update
sudo apt install -y zulu21-jdk
sudo ln -sfn /usr/lib/jvm/zulu21-ca-amd64 /usr/lib/jvm/default

# --- docker engine + compose ---------------------------------------------
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
# NOTE: the original script was missing this `sudo`, so it always failed here.
sudo apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"

# --- aws cli v2 ----------------------------------------------------------
tmpdir=$(mktemp -d)
curl -sS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o "$tmpdir/awscliv2.zip"
unzip -q -d "$tmpdir" "$tmpdir/awscliv2.zip"
sudo "$tmpdir/aws/install" --update
rm -rf "$tmpdir"

# --- github cli ----------------------------------------------------------
sudo apt install -y gh

# --- claude code ---------------------------------------------------------
curl -fsSL https://claude.ai/install.sh | bash

echo
echo "common packages installed."
echo "log out and back in for the docker group to take effect."

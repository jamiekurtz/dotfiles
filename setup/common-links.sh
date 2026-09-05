#!/bin/bash
# Symlinks both profiles need.
set -euo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)}"

mkdir -p "$HOME/.local/bin" "$HOME/.config/nvim/lua/plugins"

ln -sfn "$DOTFILES/.gitconfig" "$HOME/.gitconfig"
ln -sfn "$DOTFILES/.tmux.conf" "$HOME/.tmux.conf"
ln -sfn "$DOTFILES/shell/profile.common" "$HOME/.profile"
ln -sfn "$DOTFILES/shell/aliases.common" "$HOME/.bash_aliases"
ln -sfn "$DOTFILES/bin/clip" "$HOME/.local/bin/clip"
ln -sfn "$DOTFILES/nvim/init.lua" "$HOME/.config/nvim/init.lua"
ln -sfn "$DOTFILES/nvim/lua/plugins/blink.lua" \
  "$HOME/.config/nvim/lua/plugins/blink.lua"

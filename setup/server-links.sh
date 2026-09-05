#!/bin/bash
# Symlinks only the headless server profile needs.
set -euo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

ln -sfn "$DOTFILES/shell/profile.server" "$HOME/.profile.local"

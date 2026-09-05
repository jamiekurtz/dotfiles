#!/bin/bash
# Symlinks only the headless server profile needs.
set -euo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)}"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

ln -sfn "$DOTFILES/shell/profile.server" "$HOME/.profile.local"

# On the server, PS1 and every alias reach the user only because
# /etc/skel/.bashrc sources ~/.bash_aliases. If this jkurtz user was created
# by cloud-init without skel (or with a stripped-down one), that link never
# happens and this script has no way to fix it -- it only owns ~/.bash_aliases
# itself, not ~/.bashrc. Warn loudly rather than silently shipping a prompt
# and aliases that never load.
if [ ! -f "$HOME/.bashrc" ]; then
  cat >&2 <<'EOF'

WARNING: ~/.bashrc does not exist.
Aliases (shell/aliases.common) and the custom PS1 prompt will NOT load in
interactive shells. Add this to a new ~/.bashrc:

  if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
  fi

EOF
elif ! grep -q '\.bash_aliases' "$HOME/.bashrc"; then
  cat >&2 <<'EOF'

WARNING: ~/.bashrc exists but does not appear to source ~/.bash_aliases.
Aliases (shell/aliases.common) and the custom PS1 prompt will NOT load in
interactive shells. Add this to ~/.bashrc:

  if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
  fi

EOF
fi

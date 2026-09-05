#!/bin/bash
# Symlink the dotfiles for one profile. Package installation is separate.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES

usage() {
  cat >&2 <<EOF
usage: $(basename "$0") <desktop|server>

  desktop  sway workstation (shadowws, shadowlt)
  server   headless Debian 13, e.g. an EC2 agent box

Symlinks config for the named profile and records the choice in
~/.dotfiles-profile. Packages are installed separately:

  ./setup/common-packages.sh
  ./setup/desktop-packages.sh   # or server-packages.sh
EOF
  exit 2
}

[ $# -eq 1 ] || usage

profile="$1"
case "$profile" in
desktop | server) ;;
*) usage ;;
esac

"$DOTFILES/setup/common-links.sh"
"$DOTFILES/setup/${profile}-links.sh"

printf '%s\n' "$profile" >"$HOME/.dotfiles-profile"
printf 'linked profile: %s\n' "$profile"

#!/bin/bash
# Symlinks only the sway workstation profile needs.
set -euo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

mkdir -p \
  "$HOME/.config/sway" "$HOME/.config/foot" "$HOME/.config/mako" \
  "$HOME/.config/swappy" "$HOME/.config/i3status" \
  "$HOME/.config/xdg-desktop-portal" "$HOME/.local/bin" \
  "$HOME/.ssh/config.d"
chmod 700 "$HOME/.ssh"

ln -sfn "$DOTFILES/shell/profile.desktop" "$HOME/.profile.local"

ln -sfn "$DOTFILES/sway/config.common" "$HOME/.config/sway/config.common"
ln -sfn "$DOTFILES/sway/config.d" "$HOME/.config/sway/config.d"
ln -sfn "$DOTFILES/foot/foot.ini" "$HOME/.config/foot/foot.ini"
ln -sfn "$DOTFILES/mako/config" "$HOME/.config/mako/config"
ln -sfn "$DOTFILES/swappy/config" "$HOME/.config/swappy/config"
ln -sfn "$DOTFILES/i3status/config" "$HOME/.config/i3status/config"
ln -sfn "$DOTFILES/bin/swaycwd" "$HOME/.local/bin/swaycwd"

# Client-side ssh entry for the EC2 agent box. Never rewrite the user's own
# ~/.ssh/config -- drop a fragment in and tell them how to include it.
ln -sfn "$DOTFILES/ssh/agentbox.conf" "$HOME/.ssh/config.d/agentbox.conf"
if [ -f "$HOME/.ssh/config" ] && ! grep -q 'Include config.d/\*' "$HOME/.ssh/config"; then
  cat <<'EOF'

NOTE: add this as the FIRST line of ~/.ssh/config to pick up ssh/agentbox.conf:

  Include config.d/*

EOF
fi

# Per-host sway config. HOSTNAME_OVERRIDE exists so the test suite can exercise
# both branches on any machine.
case "${HOSTNAME_OVERRIDE:-$(hostname)}" in
shadowws) ln -sfn "$DOTFILES/sway/config-for-meerkat" "$HOME/.config/sway/config" ;;
shadowlt) ln -sfn "$DOTFILES/sway/config-for-p14" "$HOME/.config/sway/config" ;;
*) echo "unknown host, symlink ~/.config/sway/config manually" ;;
esac

# Screen sharing (Slack, Zoom) portals.
ln -sfn "$DOTFILES/xdg-desktop-portal/sway-portals.conf" \
  "$HOME/.config/xdg-desktop-portal/sway-portals.conf"
# Only restart the portals if a sway session is actually running here -- this
# script also runs under the test suite (with $HOME pointed at a temp dir),
# and pkill is not $HOME-scoped, so an unconditional restart could kill a
# real, live session's screen-sharing portals. On a fresh install sway isn't
# running yet either, and the portals start correctly with it regardless.
# pkill exits 1 when nothing matched, which set -e would treat as fatal.
if [ -n "${SWAYSOCK:-}" ]; then
  pkill -f xdg-desktop-portal || true
fi

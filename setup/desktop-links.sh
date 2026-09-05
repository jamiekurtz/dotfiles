#!/bin/bash
# Symlinks only the sway workstation profile needs.
set -euo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)}"

mkdir -p \
  "$HOME/.config/sway" "$HOME/.config/foot" "$HOME/.config/mako" \
  "$HOME/.config/swappy" "$HOME/.config/i3status" \
  "$HOME/.config/xdg-desktop-portal" "$HOME/.local/bin" \
  "$HOME/.ssh/config.d"
chmod 700 "$HOME/.ssh"
chmod 700 "$HOME/.ssh/config.d"

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
#
# This is a COPY, not a symlink: the repo ships a CHANGEME template and the
# user edits their own copy in place (the real HostName, once known). A
# symlink here would mean editing the template edits the tracked file,
# leaving the repo permanently dirty. Never overwrite an existing copy --
# the user's edits must survive re-running bootstrap.
if [ ! -e "$HOME/.ssh/config.d/agentbox.conf" ]; then
  cp "$DOTFILES/ssh/agentbox.conf.template" "$HOME/.ssh/config.d/agentbox.conf"
  chmod 600 "$HOME/.ssh/config.d/agentbox.conf"
fi
if [ -f "$HOME/.ssh/config" ] && ! grep -q 'Include config.d/\*' "$HOME/.ssh/config"; then
  cat <<'EOF'

NOTE: add this as the FIRST line of ~/.ssh/config to pick up ~/.ssh/config.d/agentbox.conf:

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
# Only restart the portals when BOTH a live sway session exists AND we are
# linking into the invoking user's real login home -- not an overridden one.
# SWAYSOCK alone is not enough: the test suite is naturally run from a foot
# terminal inside a real sway session (so SWAYSOCK is set there too) while
# overriding $HOME to a temp dir, and pkill is not $HOME-scoped. Without the
# real_home check, running the tests on a live workstation would kill the
# user's own running portals mid-session -- exactly what this gate exists to
# prevent. Do not simplify this back to just the SWAYSOCK check.
real_home="$(getent passwd "$(id -un)" | cut -d: -f6)"
if [ -n "${SWAYSOCK:-}" ] && [ "$HOME" = "$real_home" ]; then
  # pkill exits 1 when nothing matched, which set -e would treat as fatal.
  pkill -f xdg-desktop-portal || true
fi

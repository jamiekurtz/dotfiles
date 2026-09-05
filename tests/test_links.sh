#!/bin/bash
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
mkdir -p "$HOME"

# --- argument validation ---------------------------------------------------
if bash "$DOTFILES/setup/bootstrap.sh" >/dev/null 2>&1; then
  fail "bootstrap.sh with no argument should exit non-zero"
fi
if bash "$DOTFILES/setup/bootstrap.sh" nonsense >/dev/null 2>&1; then
  fail "bootstrap.sh with an unknown profile should exit non-zero"
fi
usage=$(bash "$DOTFILES/setup/bootstrap.sh" 2>&1 || true)
assert_contains "$usage" "desktop" "usage text names the desktop profile"
assert_contains "$usage" "server" "usage text names the server profile"

# --- server profile --------------------------------------------------------
bash "$DOTFILES/setup/bootstrap.sh" server ||
  fail "bootstrap.sh server exited non-zero"

assert_eq "server" "$(cat "$HOME/.dotfiles-profile")" \
  "bootstrap records the chosen profile"

assert_link "$HOME/.profile" "$DOTFILES/shell/profile.common" \
  "~/.profile links to profile.common"
assert_link "$HOME/.profile.local" "$DOTFILES/shell/profile.server" \
  "~/.profile.local links to profile.server"
assert_link "$HOME/.bash_aliases" "$DOTFILES/shell/aliases.common" \
  "~/.bash_aliases links to aliases.common"
assert_link "$HOME/.gitconfig" "$DOTFILES/.gitconfig" \
  "~/.gitconfig is linked"
assert_link "$HOME/.tmux.conf" "$DOTFILES/.tmux.conf" \
  "~/.tmux.conf is linked"
assert_link "$HOME/.local/bin/clip" "$DOTFILES/bin/clip" \
  "clip is on PATH"
assert_link "$HOME/.config/nvim/init.lua" "$DOTFILES/nvim/init.lua" \
  "nvim init.lua is linked"
assert_link "$HOME/.config/nvim/lua/plugins/blink.lua" \
  "$DOTFILES/nvim/lua/plugins/blink.lua" "blink.lua is linked"
assert_eq "700" "$(stat -c %a "$HOME/.ssh")" \
  "server-links creates ~/.ssh with 0700"

# The server profile must not link any compositor config.
for p in .config/sway .config/foot .config/mako .config/swappy .config/i3status; do
  [ -e "$HOME/$p" ] &&
    fail "server profile should not create ~/$p"
done
[ -e "$HOME/.local/bin/swaycwd" ] &&
  fail "server profile should not link swaycwd"

# --- idempotence -----------------------------------------------------------
bash "$DOTFILES/setup/bootstrap.sh" server ||
  fail "bootstrap.sh server is not safe to re-run"
assert_link "$HOME/.profile" "$DOTFILES/shell/profile.common" \
  "re-running bootstrap leaves ~/.profile correct"

# --- switching profiles re-points .profile.local ---------------------------
rm -rf "$HOME"
mkdir -p "$HOME"
HOSTNAME_OVERRIDE=shadowlt bash "$DOTFILES/setup/bootstrap.sh" desktop ||
  fail "bootstrap.sh desktop exited non-zero"
assert_eq "desktop" "$(cat "$HOME/.dotfiles-profile")" \
  "bootstrap records the desktop profile"
assert_link "$HOME/.profile.local" "$DOTFILES/shell/profile.desktop" \
  "desktop profile links profile.local to profile.desktop"
assert_link "$HOME/.config/sway/config.common" \
  "$DOTFILES/sway/config.common" "sway config.common is linked"
assert_link "$HOME/.config/foot/foot.ini" "$DOTFILES/foot/foot.ini" \
  "foot.ini is linked"
assert_link "$HOME/.local/bin/swaycwd" "$DOTFILES/bin/swaycwd" \
  "swaycwd is linked on the desktop profile"
assert_link "$HOME/.ssh/config.d/agentbox.conf" \
  "$DOTFILES/ssh/agentbox.conf" "the agentbox ssh entry is linked"

echo "test_links: ok"

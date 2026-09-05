#!/bin/bash
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Source a profile file under a throwaway HOME and echo one variable.
# Uses sh, not bash, because these files must stay POSIX.
probe() {
  file="$1"
  var="$2"
  shift 2
  env -i HOME="$tmp/home" PATH="$PATH" "$@" \
    sh -c ". '$DOTFILES/$file' >/dev/null 2>&1; printf '%s' \"\${$var:-}\""
}

mkdir -p "$tmp/home"

# --- profile.common --------------------------------------------------------
assert_eq "nvim" "$(probe shell/profile.common EDITOR)" \
  "profile.common exports EDITOR=nvim"
assert_eq "$tmp/home/go" "$(probe shell/profile.common GOPATH)" \
  "profile.common exports GOPATH"
assert_eq "/usr/lib/jvm/default" "$(probe shell/profile.common JAVA_HOME)" \
  "profile.common exports JAVA_HOME"
assert_contains "$(probe shell/profile.common PATH)" "$tmp/home/.local/bin" \
  "profile.common adds ~/.local/bin to PATH"

# profile.common must NOT launch a compositor -- that belongs to the desktop
# profile only.
content=$(cat "$DOTFILES/shell/profile.common")
case "$content" in
*"exec sway"*) fail "profile.common still contains the sway launch block" ;;
esac

# --- profile.common sources ~/.profile.local ------------------------------
echo 'export PROFILE_LOCAL_WAS_SOURCED=yes' >"$tmp/home/.profile.local"
assert_eq "yes" "$(probe shell/profile.common PROFILE_LOCAL_WAS_SOURCED)" \
  "profile.common sources ~/.profile.local"
rm "$tmp/home/.profile.local"

# Missing ~/.profile.local must not make sourcing fail.
env -i HOME="$tmp/home" PATH="$PATH" \
  sh -c ". '$DOTFILES/shell/profile.common'" ||
  fail "profile.common exits non-zero when ~/.profile.local is absent"

# --- profile.server --------------------------------------------------------
assert_eq "echo" "$(probe shell/profile.server BROWSER)" \
  "profile.server exports BROWSER=echo"
assert_contains "$(probe shell/profile.server LANG)" "UTF-8" \
  "profile.server exports a UTF-8 LANG when LANG is unset"
assert_eq "en_GB.UTF-8" "$(probe shell/profile.server LANG LANG=en_GB.UTF-8)" \
  "profile.server leaves an existing UTF-8 LANG alone"

# SSH_AUTH_SOCK stabilization: given a real socket, the exported value is the
# stable symlink path, and the symlink points at the original socket.
sockdir="$tmp/sock"
mkdir -p "$sockdir"
python3 -c "
import socket, sys
s = socket.socket(socket.AF_UNIX)
s.bind('$sockdir/agent.sock')
" || fail "could not create a test unix socket"

got=$(probe shell/profile.server SSH_AUTH_SOCK \
  SSH_AUTH_SOCK="$sockdir/agent.sock")
assert_eq "$tmp/home/.ssh/auth_sock" "$got" \
  "profile.server exports the stable auth_sock path"
assert_eq "$sockdir/agent.sock" "$(readlink "$tmp/home/.ssh/auth_sock")" \
  "profile.server points ~/.ssh/auth_sock at the forwarded socket"
assert_eq "700" "$(stat -c %a "$tmp/home/.ssh")" \
  "profile.server creates ~/.ssh with 0700"

# With no agent at all, SSH_AUTH_SOCK must be left empty rather than pointing
# at a dangling symlink.
rm -f "$tmp/home/.ssh/auth_sock"
assert_eq "" "$(probe shell/profile.server SSH_AUTH_SOCK)" \
  "profile.server exports no SSH_AUTH_SOCK when there is no agent"

# --- profile.desktop -------------------------------------------------------
content=$(cat "$DOTFILES/shell/profile.desktop")
assert_contains "$content" "exec sway" \
  "profile.desktop contains the sway launch"
assert_contains "$content" ".no-sway" \
  "profile.desktop honors the ~/.no-sway marker"

# --- aliases.common --------------------------------------------------------
content=$(cat "$DOTFILES/shell/aliases.common")
# clip is a script on PATH (bin/clip), not an alias. Assert both halves of
# that: no alias, and no leftover xclip.
case "$content" in
*"alias clip="*)
  fail "aliases.common should not alias clip; bin/clip is on PATH" ;;
*xclip*) fail "aliases.common still references xclip" ;;
esac
[ -x "$DOTFILES/bin/clip" ] || fail "bin/clip is missing or not executable"

for a in 'alias lg=' 'alias ld=' 'alias rng=' 'alias ll='; do
  assert_contains "$content" "$a" "aliases.common defines $a"
done
assert_contains "$content" '.bash_aliases.local' \
  "aliases.common sources ~/.bash_aliases.local"

echo "test_shell_profiles: ok"

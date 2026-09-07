#!/bin/bash
# Generate a git-push key that lives on this box.
#
# Interactive work should use your forwarded agent instead -- see the
# SSH_AUTH_SOCK block in shell/profile.server. This key is for agents that
# keep running after you disconnect, when there is no forwarded agent to use.
# It is opt-in because a private key on a server is not something to create
# by surprise.
set -euo pipefail

KEY="$HOME/.ssh/id_ed25519_agentbox"

usage() {
  cat >&2 <<EOF
usage: $(basename "$0") --generate-key

Creates $KEY, configures github.com to use it, and prints the public key to
add at https://github.com/settings/keys
EOF
  exit 2
}

[ "${1:-}" = "--generate-key" ] || usage

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ -f "$KEY" ] && [ -f "$KEY.pub" ]; then
  echo "$KEY already exists, leaving it alone."
elif [ -f "$KEY" ]; then
  echo "$KEY exists but $KEY.pub is missing." >&2
  echo "Regenerating the public half from the private key -- this is lossless and does not invalidate anything already registered with GitHub." >&2
  ssh-keygen -y -f "$KEY" > "$KEY.pub"
else
  if [ -f "$KEY.pub" ]; then
    echo "$KEY.pub exists but $KEY does not -- the key previously registered at https://github.com/settings/keys is now orphaned. Generating a new keypair; you will need to add the new public key at https://github.com/settings/keys and remove the old one." >&2
  fi
  ssh-keygen -t ed25519 -N "" -f "$KEY" -C "agentbox-$(hostname -s)"
fi

if ! grep -qs "$KEY" "$HOME/.ssh/config"; then
  # IdentitiesOnly yes is load-bearing, not tidiness. Without it, a forwarded
  # agent's keys are offered to github BEFORE this one, and github accepts
  # whichever valid key arrives first -- so a push succeeds while you are
  # attached and fails once you disconnect, which is the exact failure this
  # key exists to prevent and the hardest kind to debug. Pinning the identity
  # means the on-box key is exercised identically either way, so a broken
  # setup fails immediately and visibly instead of intermittently.
  cat >>"$HOME/.ssh/config" <<EOF

Host github.com
  IdentityFile "$KEY"
  IdentitiesOnly yes
EOF
  echo "Added a github.com block to ~/.ssh/config"
elif ! grep -qs 'IdentitiesOnly' "$HOME/.ssh/config"; then
  # Written by an older revision of this script. Editing a live ~/.ssh/config
  # in place is not worth the risk of mangling it, so say what to add.
  cat >&2 <<EOF

NOTE: ~/.ssh/config already has a block for this key but no IdentitiesOnly.
Add this line to the "Host github.com" block so pushes behave the same whether
or not your ssh agent is forwarded:

  IdentitiesOnly yes

EOF
fi

echo
echo "Add this public key at https://github.com/settings/keys :"
echo
cat "$KEY.pub"
echo

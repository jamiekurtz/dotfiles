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
  cat >>"$HOME/.ssh/config" <<EOF

Host github.com
  IdentityFile $KEY
  IdentitiesOnly yes
EOF
  echo "Added a github.com block to ~/.ssh/config"
fi

echo
echo "Add this public key at https://github.com/settings/keys :"
echo
cat "$KEY.pub"
echo

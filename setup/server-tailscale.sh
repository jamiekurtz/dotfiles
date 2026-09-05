#!/bin/bash
# Bring this machine onto the tailnet.
#
#   TS_AUTHKEY=tskey-auth-... ./setup/server-tailscale.sh   # unattended
#   ./setup/server-tailscale.sh                             # prints a URL
#
# The interactive form prints an auth URL rather than opening a browser, which
# is exactly what you want here -- shell/profile.server sets BROWSER=echo.
set -euo pipefail

if ! command -v tailscale >/dev/null 2>&1; then
  echo "tailscale is not installed -- run ./setup/server-packages.sh first" >&2
  exit 1
fi

hostname_flag="--hostname=$(hostname -s)"

if [ -n "${TS_AUTHKEY:-}" ]; then
  sudo tailscale up "$hostname_flag" --authkey="$TS_AUTHKEY"
else
  echo "No TS_AUTHKEY set. Open the URL below on any machine to authorize:"
  echo
  sudo tailscale up "$hostname_flag"
fi

echo
tailscale status
echo
echo "Add the MagicDNS name above to ssh/agentbox.conf on your workstation."

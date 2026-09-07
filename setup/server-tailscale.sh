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

# `tailscale status` above shows the SHORT hostname and the 100.x IP, but not
# the tailnet suffix, so there is nothing in it to paste into a MagicDNS
# HostName. The full name lives in --json as .Self.DNSName (with a trailing
# dot). Print the ready-to-paste line rather than making the reader assemble it.
fqdn=""
if command -v jq >/dev/null 2>&1; then
  fqdn=$(tailscale status --json | jq -r '.Self.DNSName // empty' | sed 's/\.$//')
fi

echo "On your workstation, put this in ~/.ssh/config.d/agentbox.conf:"
echo
if [ -n "$fqdn" ]; then
  echo "  HostName $fqdn"
else
  # jq is installed by common-packages.sh, so this is the out-of-order case.
  echo "  (could not read the MagicDNS name -- jq is not installed)"
  echo "  Run: tailscale status --json | jq -r .Self.DNSName"
  echo "  or just use the short name or the 100.x IP shown above."
fi
echo
echo "The bare short name or the 100.x IP from the table above also work."

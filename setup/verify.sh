#!/bin/bash
# Syntax-check every script in the repo, and shellcheck them when available.
set -uo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DOTFILES"

status=0

# Build glob-safe file lists. A glob that matches nothing must not be passed
# through as a literal unexpanded pattern (e.g. "shell/*" before shell/
# exists) -- that breaks bash -n and makes shellcheck error on a missing
# file. nullglob makes an unmatched glob expand to nothing instead.
shopt -s nullglob
shell_files=(shell/profile.*)
checked_files=(setup/*.sh tests/*.sh bin/* shell/aliases.common)
shopt -u nullglob

# shell/profile.* must be POSIX sh, so check them with sh -n as well.
for f in "${shell_files[@]}"; do
  [ -f "$f" ] || continue
  sh -n "$f" || { echo "sh -n failed: $f" >&2; status=1; }
done

for f in "${checked_files[@]}"; do
  [ -f "$f" ] || continue
  bash -n "$f" || { echo "bash -n failed: $f" >&2; status=1; }
done

if command -v shellcheck >/dev/null 2>&1; then
  all_files=("${checked_files[@]}" "${shell_files[@]}")
  if [ "${#all_files[@]}" -gt 0 ]; then
    shellcheck --severity=warning "${all_files[@]}" || status=1
  fi
else
  echo "shellcheck not installed, skipping (apt install shellcheck)"
fi

[ "$status" -eq 0 ] && echo "verify: ok"
exit "$status"

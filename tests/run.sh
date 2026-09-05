#!/bin/bash
# Run every tests/test_*.sh. Exit non-zero if any fails.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")" || exit

failed=0
for t in test_*.sh; do
  if bash "$t"; then
    printf '  ok   %s\n' "$t"
  else
    printf '  FAIL %s\n' "$t"
    failed=$((failed + 1))
  fi
done

if [ "$failed" -gt 0 ]; then
  printf '\n%d test file(s) failed\n' "$failed" >&2
  exit 1
fi
printf '\nall tests passed\n'

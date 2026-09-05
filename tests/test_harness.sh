#!/bin/bash
# Tests for the test harness itself.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

assert_eq "abc" "abc" "assert_eq accepts equal strings"
assert_contains "hello world" "lo wo" "assert_contains finds a substring"

# A failing assertion must exit non-zero. Run one in a subshell so this file
# survives it.
( assert_eq "a" "b" "deliberate failure" ) >/dev/null 2>&1
if [ $? -eq 0 ]; then
  fail "assert_eq returned success on unequal strings"
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
echo target >"$tmp/target"
ln -s "$tmp/target" "$tmp/link"
assert_link "$tmp/link" "$tmp/target" "assert_link accepts a resolvable link"

( assert_link "$tmp/missing" "$tmp/target" "deliberate failure" ) >/dev/null 2>&1
if [ $? -eq 0 ]; then
  fail "assert_link returned success on a nonexistent path"
fi

echo "test_harness: ok"

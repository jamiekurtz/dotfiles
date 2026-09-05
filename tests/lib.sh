# shellcheck shell=bash
# Assertion helpers for the dotfiles shell tests.
# Source this; do not execute it.

_show() {
  # Render a value readably: od -c when it contains control characters,
  # plain otherwise.
  case "$1" in
  *[![:print:][:space:]]* | *$'\033'* | *$'\a'*)
    printf '%s' "$1" | od -c | sed 's/^/      /'
    ;;
  *)
    printf '      %s\n' "$1"
    ;;
  esac
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_eq() {
  expected="$1"
  actual="$2"
  message="$3"
  if [ "$expected" != "$actual" ]; then
    printf 'FAIL: %s\n    expected:\n' "$message" >&2
    _show "$expected" >&2
    printf '    actual:\n' >&2
    _show "$actual" >&2
    exit 1
  fi
}

assert_contains() {
  haystack="$1"
  needle="$2"
  message="$3"
  case "$haystack" in
  *"$needle"*) ;;
  *)
    printf 'FAIL: %s\n    %s\n    does not contain:\n    %s\n' \
      "$message" "$haystack" "$needle" >&2
    exit 1
    ;;
  esac
}

assert_link() {
  link="$1"
  expected="$2"
  message="$3"
  [ -L "$link" ] || fail "$message: $link is not a symlink"
  actual=$(readlink "$link")
  [ "$actual" = "$expected" ] ||
    fail "$message: $link -> $actual, expected $expected"
  [ -e "$link" ] ||
    fail "$message: $link points at a nonexistent target ($actual)"
}

#!/bin/bash
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

CLIP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bin/clip"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

ESC=$'\033'
BEL=$'\a'
# "hello" | base64 -> aGVsbG8=
B64="aGVsbG8="

# --- remote, outside tmux: bare OSC 52 -------------------------------------
out="$tmp/bare"
printf 'hello' |
  env -u WAYLAND_DISPLAY -u TMUX CLIP_TTY="$out" "$CLIP"
assert_eq "${ESC}]52;c;${B64}${BEL}" "$(cat "$out")" \
  "outside tmux, clip writes a bare OSC 52 sequence"

# --- remote, inside tmux: DCS-wrapped, inner ESC doubled -------------------
out="$tmp/tmux"
printf 'hello' |
  env -u WAYLAND_DISPLAY TMUX=/tmp/tmux-1000/default,123,0 \
    CLIP_TTY="$out" "$CLIP"
assert_eq "${ESC}Ptmux;${ESC}${ESC}]52;c;${B64}${BEL}${ESC}\\" \
  "$(cat "$out")" \
  "inside tmux, clip wraps OSC 52 in a DCS passthrough with ESC doubled"

# --- trailing newline is stripped -----------------------------------------
out="$tmp/newline"
printf 'hello\n' |
  env -u WAYLAND_DISPLAY -u TMUX CLIP_TTY="$out" "$CLIP"
assert_eq "${ESC}]52;c;${B64}${BEL}" "$(cat "$out")" \
  "a trailing newline on stdin is not copied"

# --- multi-line input survives --------------------------------------------
out="$tmp/multi"
printf 'a\nb' | env -u WAYLAND_DISPLAY -u TMUX CLIP_TTY="$out" "$CLIP"
# "a\nb" | base64 -> YQpi
assert_eq "${ESC}]52;c;YQpi${BEL}" "$(cat "$out")" \
  "embedded newlines are preserved in the payload"

# --- base64 payload is never line-wrapped ---------------------------------
out="$tmp/long"
head -c 400 /dev/zero | tr '\0' 'x' |
  env -u WAYLAND_DISPLAY -u TMUX CLIP_TTY="$out" "$CLIP"
lines=$(tr -cd '\n' <"$out" | wc -c | tr -d ' ')
assert_eq "0" "$lines" "long payloads produce no embedded newlines"

# --- Wayland path prefers wl-copy -----------------------------------------
# Shim wl-copy onto PATH and confirm it is used instead of the escape sequence.
mkdir -p "$tmp/bin"
cat >"$tmp/bin/wl-copy" <<'SHIM'
#!/bin/bash
cat >"$WL_COPY_OUT"
SHIM
chmod +x "$tmp/bin/wl-copy"
out="$tmp/wayland"
touch "$out"
printf 'hello' |
  env -u TMUX PATH="$tmp/bin:$PATH" WAYLAND_DISPLAY=wayland-1 \
    WL_COPY_OUT="$tmp/wl-copy-received" CLIP_TTY="$out" "$CLIP"
assert_eq "hello" "$(cat "$tmp/wl-copy-received")" \
  "with WAYLAND_DISPLAY set, clip pipes to wl-copy"
assert_eq "" "$(cat "$out")" \
  "with WAYLAND_DISPLAY set, clip writes nothing to the tty"

echo "test_clip: ok"

# Headless Debian 13 Server Profile — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split this dotfiles repo into a `desktop` profile (existing sway
workstations) and a `server` profile (headless Debian 13 on EC2), so one
checkout configures either kind of machine.

**Architecture:** Tool config directories keep their current paths. Shell files
move into `shell/` and gain a `common` + per-profile split wired together by a
`~/.profile.local` symlink. One `setup/bootstrap.sh <profile>` entry point calls
`common-links.sh` then `<profile>-links.sh`; package installation is a separate
manual step split the same three ways. Clipboard crosses SSH via OSC 52 rather
than X forwarding.

**Tech Stack:** POSIX sh and bash, GNU coreutils, tmux 3.5, neovim 0.11+
(Lua), Debian 13 apt, Docker (for the integration test), Tailscale.

**Spec:** `docs/superpowers/specs/2026-09-05-headless-server-profile-design.md`

## Global Constraints

- Target OS is **Debian 13** only. Do not add compatibility shims for other
  distributions.
- Server user is **`jkurtz`**. Repo lives at **`~/wd/dotfiles`** on both
  profiles.
- Scripts must be **idempotent** — safe to re-run. Use `ln -sfn`, `mkdir -p`.
- Every script under `setup/` starts with `#!/bin/bash` and `set -euo pipefail`
  unless the task text says otherwise, and is `chmod +x`.
- `shell/profile.*` files are sourced by `/bin/sh` as well as bash. Use **POSIX
  sh only** in them: no `[[`, no arrays, no `local` outside functions. Guard
  every possibly-unset variable with `${VAR:-}`.
- Files that both profiles use must be **inert on the profile that does not
  need them** — never conditional on hostname where a capability check will do.
- No new runtime dependency for the test suite. Tests are plain bash.
- Commit after every task. Conventional-commit style (`feat:`, `fix:`,
  `refactor:`, `docs:`, `test:`).

## File Structure

| Path | Responsibility |
|---|---|
| `tests/lib.sh` | Assertion helpers for the shell test suite. No deps. |
| `tests/run.sh` | Discovers and runs `tests/test_*.sh`, reports pass/fail. |
| `tests/test_clip.sh` | Behavior of `bin/clip` in each environment. |
| `tests/test_shell_profiles.sh` | What `profile.common`/`.server` export. |
| `tests/test_links.sh` | `bootstrap.sh` link results against a fake `$HOME`. |
| `bin/clip` | stdin → clipboard: wl-copy locally, OSC 52 remotely. |
| `shell/profile.common` | PATH, `EDITOR`, `JAVA_HOME`, `GOPATH`; sources `~/.profile.local`. |
| `shell/profile.desktop` | The `exec sway` launch block. |
| `shell/profile.server` | `BROWSER=echo`, UTF-8 locale, SSH agent socket stabilization. |
| `shell/aliases.common` | Every alias (no per-profile alias files). |
| `setup/bootstrap.sh` | Entry point. Validates profile, runs link scripts, records choice. |
| `setup/common-links.sh` | Symlinks both profiles need. |
| `setup/desktop-links.sh` | Sway/foot/mako/portal symlinks + per-host sway config. |
| `setup/server-links.sh` | `~/.profile.local` + `~/.ssh` permissions. |
| `setup/common-packages.sh` | Terminal toolchain for both profiles. |
| `setup/desktop-packages.sh` | Everything needing a display. |
| `setup/server-packages.sh` | Tailscale, mosh, locales. |
| `setup/server-tailscale.sh` | `tailscale up`, authkey or printed URL. |
| `setup/server-ssh.sh` | Opt-in `--generate-key` for unattended git pushes. |
| `setup/verify.sh` | `bash -n` + shellcheck over all scripts. |
| `setup/test-in-docker.sh` | Runs the server profile inside `debian:13`. |
| `ssh/agentbox.conf` | Client-side `Host agentbox` entry. |
| `docs/desktop-notes.md` | Former `setup/new-sway-followup.md`. |

**Deviations from the spec, both deliberate:**

1. The spec's `profile.server` sets `LANG` *and* `LC_ALL`. This plan sets only
   `LANG`. `LC_ALL` overrides every other category unconditionally and is
   hostile to anyone who later wants a different `LC_TIME`; `LANG` is
   sufficient to fix the mojibake this is aimed at.
2. The spec folds `setup/new-sway-followup.md` into `readme.md`. This plan
   moves it to `docs/desktop-notes.md` and links it from `readme.md` instead,
   so the readme stays a getting-started document rather than absorbing three
   pages of desktop troubleshooting.

---

### Task 1: Shell test harness

Nothing in this repo is currently tested. Every later task writes tests
against this harness, so it comes first.

**Files:**
- Create: `tests/lib.sh`
- Create: `tests/run.sh`
- Create: `tests/test_harness.sh`
- Create: `setup/verify.sh`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `assert_eq <expected> <actual> <message>` — exits the current test file
    non-zero on mismatch, printing both values through `od -c` when either
    contains a control character.
  - `assert_contains <haystack> <needle> <message>`
  - `assert_link <link_path> <expected_target> <message>` — asserts the path is
    a symlink *and* that it resolves to an existing file.
  - `fail <message>` — prints and exits 1.
  - `pass_count` / `fail_count` — integers a test file increments implicitly
    via the asserts; `tests/run.sh` reads the exit status only.
  - `tests/run.sh` — exit 0 iff every `tests/test_*.sh` exits 0.

- [ ] **Step 1: Write the failing test**

Create `tests/test_harness.sh`:

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_harness.sh`
Expected: FAIL — `tests/lib.sh: No such file or directory`

- [ ] **Step 3: Write minimal implementation**

Create `tests/lib.sh`:

```bash
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
```

Create `tests/run.sh`:

```bash
#!/bin/bash
# Run every tests/test_*.sh. Exit non-zero if any fails.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

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
```

Create `setup/verify.sh`:

```bash
#!/bin/bash
# Syntax-check every script in the repo, and shellcheck them when available.
set -uo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DOTFILES"

status=0

# shell/profile.* must be POSIX sh, so check them with sh -n as well.
for f in shell/*; do
  [ -f "$f" ] || continue
  sh -n "$f" || { echo "sh -n failed: $f" >&2; status=1; }
done

for f in setup/*.sh tests/*.sh bin/*; do
  [ -f "$f" ] || continue
  bash -n "$f" || { echo "bash -n failed: $f" >&2; status=1; }
done

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck --severity=warning setup/*.sh tests/*.sh bin/* shell/* ||
    status=1
else
  echo "shellcheck not installed, skipping (apt install shellcheck)"
fi

[ "$status" -eq 0 ] && echo "verify: ok"
exit "$status"
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `chmod +x tests/run.sh setup/verify.sh && bash tests/run.sh && bash setup/verify.sh`
Expected: `test_harness: ok`, `ok   test_harness.sh`, `all tests passed`, then
`verify: ok` (or the shellcheck-not-installed notice).

- [ ] **Step 5: Commit**

```bash
git add tests setup/verify.sh
git commit -m "test: add shell test harness and script verifier"
```

---

### Task 2: `bin/clip` — clipboard that works locally and over SSH

The current `alias clip="xclip -selection clipboard"` is broken: both
workstations run Wayland, where `xclip` talks to an X server that is not
there. Replacing it with one script that works on both profiles.

**Files:**
- Create: `bin/clip`
- Create: `tests/test_clip.sh`

**Interfaces:**
- Consumes: `assert_eq` from `tests/lib.sh`.
- Produces: `bin/clip` — reads stdin, writes the clipboard. Honors
  `WAYLAND_DISPLAY` (use `wl-copy`), `TMUX` (wrap OSC 52 in a DCS
  passthrough), and `CLIP_TTY` (where to write the escape sequence; defaults
  to `/dev/tty`, overridable so the behavior is testable).

**Background the implementer needs:** OSC 52 is the terminal escape sequence
`ESC ] 52 ; c ; <base64> BEL`. A terminal that receives it puts the decoded
payload on the system clipboard — which is how a copy on the EC2 box reaches
the laptop, with no X forwarding and no daemon. Written from inside tmux it is
swallowed, so it must be wrapped in tmux's DCS passthrough: `ESC P tmux ;`,
then the sequence with **every ESC byte doubled**, then `ESC \`.

- [ ] **Step 1: Write the failing test**

Create `tests/test_clip.sh`:

```bash
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
  env PATH="$tmp/bin:$PATH" WAYLAND_DISPLAY=wayland-1 -u TMUX \
    WL_COPY_OUT="$tmp/wl-copy-received" CLIP_TTY="$out" "$CLIP"
assert_eq "hello" "$(cat "$tmp/wl-copy-received")" \
  "with WAYLAND_DISPLAY set, clip pipes to wl-copy"
assert_eq "" "$(cat "$out")" \
  "with WAYLAND_DISPLAY set, clip writes nothing to the tty"

echo "test_clip: ok"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_clip.sh`
Expected: FAIL — `bin/clip: No such file or directory`

- [ ] **Step 3: Write minimal implementation**

Create `bin/clip`:

```bash
#!/bin/sh
# Copy stdin to the clipboard, whichever clipboard is actually reachable.
#
#   Wayland session present -> wl-copy, the real local clipboard.
#   Otherwise (i.e. over SSH) -> an OSC 52 escape sequence written to the
#   terminal, which puts the text on the clipboard of whatever machine is
#   drawing the pixels. No X forwarding, no daemon.
#
# Inside tmux a bare OSC 52 is swallowed, so it is wrapped in tmux's DCS
# passthrough with every inner ESC byte doubled.
#
# CLIP_TTY overrides the output device; it exists so the escape-sequence
# behavior can be tested without a terminal.
set -eu

input=$(cat)

if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
  printf '%s' "$input" | wl-copy
  exit 0
fi

payload=$(printf '%s' "$input" | base64 | tr -d '\n')
tty_out="${CLIP_TTY:-/dev/tty}"

if [ -n "${TMUX:-}" ]; then
  printf '\033Ptmux;\033\033]52;c;%s\a\033\\' "$payload" >"$tty_out"
else
  printf '\033]52;c;%s\a' "$payload" >"$tty_out"
fi
```

`input=$(cat)` strips trailing newlines, which is what you want from a
clipboard helper — `pwd | clip` should not paste a stray newline.

- [ ] **Step 4: Run test to verify it passes**

Run: `chmod +x bin/clip && bash tests/test_clip.sh && bash tests/run.sh`
Expected: `test_clip: ok` and `all tests passed`.

- [ ] **Step 5: Commit**

```bash
git add bin/clip tests/test_clip.sh
git commit -m "feat: add bin/clip, replacing the broken xclip alias"
```

---

### Task 3: Split the shell files

**Files:**
- Create: `shell/profile.common` (via `git mv .profile shell/profile.common`, then edit)
- Create: `shell/profile.desktop`
- Create: `shell/profile.server`
- Create: `shell/aliases.common` (via `git mv .bash_aliases shell/aliases.common`, then edit)
- Create: `tests/test_shell_profiles.sh`
- Delete: `.profile`, `.bash_aliases` (as the result of the `git mv`)

**Interfaces:**
- Consumes: `assert_eq`, `assert_contains` from `tests/lib.sh`.
- Produces:
  - `shell/profile.common` — sourced as `~/.profile`. Exports `PATH`
    additions, `EDITOR=nvim`, `GOPATH=$HOME/go`,
    `JAVA_HOME=/usr/lib/jvm/default`, `LEFTHOOK=0`. Ends by sourcing
    `~/.profile.local` when it exists.
  - `shell/profile.server` — exports `BROWSER=echo`, a UTF-8 `LANG`, and a
    stabilized `SSH_AUTH_SOCK` at `$HOME/.ssh/auth_sock`.
  - `shell/profile.desktop` — `exec sway` on tty1, honoring `~/.no-sway`.
  - `shell/aliases.common` — sourced as `~/.bash_aliases`. Ends by sourcing
    `~/.bash_aliases.local` when it exists.

**Why there is no `aliases.desktop`/`aliases.server`:** every alias in the
current file is a terminal or docker helper, and both profiles install the same
terminal toolchain. A per-profile alias file would be machinery for a
distinction that does not exist. The `.local` sourcing hook is still there, so
adding one later needs no restructuring.

- [ ] **Step 1: Write the failing test**

Create `tests/test_shell_profiles.sh`:

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_shell_profiles.sh`
Expected: FAIL — `shell/profile.common` does not exist.

- [ ] **Step 3: Write minimal implementation**

Move the existing files so git keeps their history:

```bash
mkdir -p shell
git mv .profile shell/profile.common
git mv .bash_aliases shell/aliases.common
```

Then rewrite `shell/profile.common` as:

```sh
# ~/.profile — executed by the command interpreter for login shells.
# Symlinked from ~/wd/dotfiles/shell/profile.common.
#
# Anything specific to one kind of machine lives in ~/.profile.local, which
# setup/bootstrap.sh symlinks to shell/profile.desktop or shell/profile.server.
#
# POSIX sh only: this file is sourced by /bin/sh as well as bash.

# Bash also reads .bashrc for interactive shells, but login shells don't get
# it automatically — pull it in here so aliases are available even in a login
# shell.
if [ -n "${BASH_VERSION:-}" ]; then
  if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
  fi
fi

# --- PATH --------------------------------------------------------------
# Each entry only gets added if the directory actually exists on this
# machine, so a layout difference between machines never leaves a dangling,
# harmless-but-confusing PATH entry -- it's just silently skipped.
path_add() {
  case ":$PATH:" in
  *":$1:"*) ;; # already present, don't duplicate
  *) export PATH="$PATH:$1" ;;
  esac
}

path_add "$HOME/.local/bin"
path_add "/usr/local/go/bin"
path_add "$HOME/go/bin"
path_add "$HOME/jamie-sync/bin"
path_add "/opt/nvim-linux-x86_64/bin"

unset -f path_add

export EDITOR=nvim
export GOPATH="$HOME/go"
export JAVA_HOME=/usr/lib/jvm/default
export LEFTHOOK=0

# --- Profile-specific ----------------------------------------------------
if [ -f "$HOME/.profile.local" ]; then
  . "$HOME/.profile.local"
fi
```

Note the original `path_add` comment mentioned "the Meerkat and the P14"
specifically; it has been generalized because the same file now runs on EC2.

Create `shell/profile.desktop`:

```sh
# Desktop profile — sway workstation.
# Sourced from ~/.profile via the ~/.profile.local symlink.

# Start Sway on tty1 if we're not already in a Wayland session.
# `touch ~/.no-sway` disables this without editing the repo.
if [ -z "${WAYLAND_DISPLAY:-}" ] &&
  [ "${XDG_VTNR:-}" = 1 ] &&
  [ ! -f "$HOME/.no-sway" ]; then
  exec sway
fi
```

Create `shell/profile.server`:

```sh
# Server profile — headless Debian 13 (EC2).
# Sourced from ~/.profile via the ~/.profile.local symlink.

# There is no browser here. OAuth device flows (Claude Code, gh auth login,
# tailscale up) honor $BROWSER, so `echo` makes them print the URL into the
# terminal for you to open on whatever machine you are sitting at.
export BROWSER=echo

# Debian cloud images frequently boot with LANG unset, which turns Nerd Font
# glyphs and box-drawing characters into mojibake in neovim and lazygit.
# Leave an existing UTF-8 locale alone.
case "${LANG:-}" in
*UTF-8 | *utf8 | *UTF8) ;;
*) export LANG=en_US.UTF-8 ;;
esac

# A forwarded SSH agent gets a fresh socket path on every connection, so a
# long-lived tmux pane ends up holding a dead one and git push starts failing
# after a reconnect. Keep a stable symlink and export that instead: each new
# login re-points the symlink, and existing panes recover on their own.
if [ -n "${SSH_AUTH_SOCK:-}" ] &&
  [ -S "$SSH_AUTH_SOCK" ] &&
  [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/auth_sock" ]; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/auth_sock"
fi

# Only export it if it actually resolves — a dangling symlink here makes every
# ssh and git command hang on a socket that will never answer.
if [ -S "$HOME/.ssh/auth_sock" ]; then
  export SSH_AUTH_SOCK="$HOME/.ssh/auth_sock"
fi
```

Then edit `shell/aliases.common`. Delete this line — `bin/clip` is symlinked
onto `PATH` as `~/.local/bin/clip`, so `clip` resolves as a command and needs
no alias:

```sh
alias clip="xclip -selection clipboard"
```

Remove the `JAVA_HOME`, `GOPATH`, and `LEFTHOOK` exports too — they moved to
`profile.common`. Then append to the end of `shell/aliases.common`:

```sh
# Profile-specific aliases, if this machine ever needs any.
if [ -f "$HOME/.bash_aliases.local" ]; then
  . "$HOME/.bash_aliases.local"
fi
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/run.sh && bash setup/verify.sh`
Expected: `test_shell_profiles: ok`, `all tests passed`, `verify: ok`.

- [ ] **Step 5: Commit**

```bash
git add -A shell tests/test_shell_profiles.sh
git commit -m "refactor: split shell config into common and per-profile files"
```

---

### Task 4: `bootstrap.sh` and the three link scripts

**Files:**
- Create: `setup/bootstrap.sh`
- Create: `setup/common-links.sh`
- Create: `setup/desktop-links.sh`
- Create: `setup/server-links.sh`
- Create: `ssh/agentbox.conf`
- Create: `tests/test_links.sh`
- Delete: `setup/new-sway-links.sh`, `setup/new-i3-links.sh`

**Interfaces:**
- Consumes: `shell/profile.{common,desktop,server}`, `shell/aliases.common`,
  `bin/clip` from Task 3 and Task 2; `assert_link` from Task 1.
- Produces:
  - `setup/bootstrap.sh <desktop|server>` — exit 2 with usage on a bad or
    missing argument; otherwise runs `common-links.sh` then
    `<profile>-links.sh` and writes the profile name to
    `~/.dotfiles-profile`.
  - Each link script honors `$DOTFILES` when already exported and otherwise
    derives it from its own location, so it works standalone and from
    bootstrap.

- [ ] **Step 1: Write the failing test**

Create `tests/test_links.sh`:

```bash
#!/bin/bash
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
mkdir -p "$HOME"

# --- argument validation ---------------------------------------------------
if bash "$DOTFILES/setup/bootstrap.sh" >/dev/null 2>&1; then
  fail "bootstrap.sh with no argument should exit non-zero"
fi
if bash "$DOTFILES/setup/bootstrap.sh" nonsense >/dev/null 2>&1; then
  fail "bootstrap.sh with an unknown profile should exit non-zero"
fi
usage=$(bash "$DOTFILES/setup/bootstrap.sh" 2>&1 || true)
assert_contains "$usage" "desktop" "usage text names the desktop profile"
assert_contains "$usage" "server" "usage text names the server profile"

# --- server profile --------------------------------------------------------
bash "$DOTFILES/setup/bootstrap.sh" server ||
  fail "bootstrap.sh server exited non-zero"

assert_eq "server" "$(cat "$HOME/.dotfiles-profile")" \
  "bootstrap records the chosen profile"

assert_link "$HOME/.profile" "$DOTFILES/shell/profile.common" \
  "~/.profile links to profile.common"
assert_link "$HOME/.profile.local" "$DOTFILES/shell/profile.server" \
  "~/.profile.local links to profile.server"
assert_link "$HOME/.bash_aliases" "$DOTFILES/shell/aliases.common" \
  "~/.bash_aliases links to aliases.common"
assert_link "$HOME/.gitconfig" "$DOTFILES/.gitconfig" \
  "~/.gitconfig is linked"
assert_link "$HOME/.tmux.conf" "$DOTFILES/.tmux.conf" \
  "~/.tmux.conf is linked"
assert_link "$HOME/.local/bin/clip" "$DOTFILES/bin/clip" \
  "clip is on PATH"
assert_link "$HOME/.config/nvim/init.lua" "$DOTFILES/nvim/init.lua" \
  "nvim init.lua is linked"
assert_link "$HOME/.config/nvim/lua/plugins/blink.lua" \
  "$DOTFILES/nvim/lua/plugins/blink.lua" "blink.lua is linked"
assert_eq "700" "$(stat -c %a "$HOME/.ssh")" \
  "server-links creates ~/.ssh with 0700"

# The server profile must not link any compositor config.
for p in .config/sway .config/foot .config/mako .config/swappy .config/i3status; do
  [ -e "$HOME/$p" ] &&
    fail "server profile should not create ~/$p"
done
[ -e "$HOME/.local/bin/swaycwd" ] &&
  fail "server profile should not link swaycwd"

# --- idempotence -----------------------------------------------------------
bash "$DOTFILES/setup/bootstrap.sh" server ||
  fail "bootstrap.sh server is not safe to re-run"
assert_link "$HOME/.profile" "$DOTFILES/shell/profile.common" \
  "re-running bootstrap leaves ~/.profile correct"

# --- switching profiles re-points .profile.local ---------------------------
rm -rf "$HOME"
mkdir -p "$HOME"
HOSTNAME_OVERRIDE=shadowlt bash "$DOTFILES/setup/bootstrap.sh" desktop ||
  fail "bootstrap.sh desktop exited non-zero"
assert_eq "desktop" "$(cat "$HOME/.dotfiles-profile")" \
  "bootstrap records the desktop profile"
assert_link "$HOME/.profile.local" "$DOTFILES/shell/profile.desktop" \
  "desktop profile links profile.local to profile.desktop"
assert_link "$HOME/.config/sway/config.common" \
  "$DOTFILES/sway/config.common" "sway config.common is linked"
assert_link "$HOME/.config/foot/foot.ini" "$DOTFILES/foot/foot.ini" \
  "foot.ini is linked"
assert_link "$HOME/.local/bin/swaycwd" "$DOTFILES/bin/swaycwd" \
  "swaycwd is linked on the desktop profile"
assert_link "$HOME/.ssh/config.d/agentbox.conf" \
  "$DOTFILES/ssh/agentbox.conf" "the agentbox ssh entry is linked"

echo "test_links: ok"
```

The desktop half of this test runs on any machine because `desktop-links.sh`
reads the hostname from `${HOSTNAME_OVERRIDE:-$(hostname)}` — see the
implementation below.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_links.sh`
Expected: FAIL — `setup/bootstrap.sh: No such file or directory`

- [ ] **Step 3: Write minimal implementation**

Create `setup/bootstrap.sh`:

```bash
#!/bin/bash
# Symlink the dotfiles for one profile. Package installation is separate.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES

usage() {
  cat >&2 <<EOF
usage: $(basename "$0") <desktop|server>

  desktop  sway workstation (shadowws, shadowlt)
  server   headless Debian 13, e.g. an EC2 agent box

Symlinks config for the named profile and records the choice in
~/.dotfiles-profile. Packages are installed separately:

  ./setup/common-packages.sh
  ./setup/desktop-packages.sh   # or server-packages.sh
EOF
  exit 2
}

[ $# -eq 1 ] || usage

profile="$1"
case "$profile" in
desktop | server) ;;
*) usage ;;
esac

"$DOTFILES/setup/common-links.sh"
"$DOTFILES/setup/${profile}-links.sh"

printf '%s\n' "$profile" >"$HOME/.dotfiles-profile"
printf 'linked profile: %s\n' "$profile"
```

Create `setup/common-links.sh`:

```bash
#!/bin/bash
# Symlinks both profiles need.
set -euo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

mkdir -p "$HOME/.local/bin" "$HOME/.config/nvim/lua/plugins"

ln -sfn "$DOTFILES/.gitconfig" "$HOME/.gitconfig"
ln -sfn "$DOTFILES/.tmux.conf" "$HOME/.tmux.conf"
ln -sfn "$DOTFILES/shell/profile.common" "$HOME/.profile"
ln -sfn "$DOTFILES/shell/aliases.common" "$HOME/.bash_aliases"
ln -sfn "$DOTFILES/bin/clip" "$HOME/.local/bin/clip"
ln -sfn "$DOTFILES/nvim/init.lua" "$HOME/.config/nvim/init.lua"
ln -sfn "$DOTFILES/nvim/lua/plugins/blink.lua" \
  "$HOME/.config/nvim/lua/plugins/blink.lua"
```

Create `setup/server-links.sh`:

```bash
#!/bin/bash
# Symlinks only the headless server profile needs.
set -euo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

ln -sfn "$DOTFILES/shell/profile.server" "$HOME/.profile.local"
```

Create `setup/desktop-links.sh`:

```bash
#!/bin/bash
# Symlinks only the sway workstation profile needs.
set -euo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

mkdir -p \
  "$HOME/.config/sway" "$HOME/.config/foot" "$HOME/.config/mako" \
  "$HOME/.config/swappy" "$HOME/.config/i3status" \
  "$HOME/.config/xdg-desktop-portal" "$HOME/.local/bin" \
  "$HOME/.ssh/config.d"
chmod 700 "$HOME/.ssh"

ln -sfn "$DOTFILES/shell/profile.desktop" "$HOME/.profile.local"

ln -sfn "$DOTFILES/sway/config.common" "$HOME/.config/sway/config.common"
ln -sfn "$DOTFILES/sway/config.d" "$HOME/.config/sway/config.d"
ln -sfn "$DOTFILES/foot/foot.ini" "$HOME/.config/foot/foot.ini"
ln -sfn "$DOTFILES/mako/config" "$HOME/.config/mako/config"
ln -sfn "$DOTFILES/swappy/config" "$HOME/.config/swappy/config"
ln -sfn "$DOTFILES/i3status/config" "$HOME/.config/i3status/config"
ln -sfn "$DOTFILES/bin/swaycwd" "$HOME/.local/bin/swaycwd"

# Client-side ssh entry for the EC2 agent box. Never rewrite the user's own
# ~/.ssh/config -- drop a fragment in and tell them how to include it.
ln -sfn "$DOTFILES/ssh/agentbox.conf" "$HOME/.ssh/config.d/agentbox.conf"
if [ -f "$HOME/.ssh/config" ] && ! grep -q 'Include config.d/\*' "$HOME/.ssh/config"; then
  cat <<'EOF'

NOTE: add this as the FIRST line of ~/.ssh/config to pick up ssh/agentbox.conf:

  Include config.d/*

EOF
fi

# Per-host sway config. HOSTNAME_OVERRIDE exists so the test suite can exercise
# both branches on any machine.
case "${HOSTNAME_OVERRIDE:-$(hostname)}" in
shadowws) ln -sfn "$DOTFILES/sway/config-for-meerkat" "$HOME/.config/sway/config" ;;
shadowlt) ln -sfn "$DOTFILES/sway/config-for-p14" "$HOME/.config/sway/config" ;;
*) echo "unknown host, symlink ~/.config/sway/config manually" ;;
esac

# Screen sharing (Slack, Zoom) portals.
ln -sfn "$DOTFILES/xdg-desktop-portal/sway-portals.conf" \
  "$HOME/.config/xdg-desktop-portal/sway-portals.conf"
# pkill exits 1 when nothing matched, which set -e would treat as fatal.
pkill -f xdg-desktop-portal || true
```

Create `ssh/agentbox.conf`:

```
# Client-side entry for the headless EC2 agent box, reached over Tailscale.
# Linked to ~/.ssh/config.d/agentbox.conf by setup/desktop-links.sh.
# Requires `Include config.d/*` as the first line of ~/.ssh/config.
#
# Replace the HostName with the box's MagicDNS name once `tailscale up` has
# run there: `tailscale status` on either machine will show it.

Host agentbox
  HostName agentbox.CHANGEME.ts.net
  User jkurtz
  ForwardAgent yes
  ServerAliveInterval 30
  ServerAliveCountMax 6
```

Remove the superseded scripts:

```bash
git rm setup/new-sway-links.sh setup/new-i3-links.sh
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `chmod +x setup/*.sh && bash tests/run.sh && bash setup/verify.sh`
Expected: `test_links: ok`, `all tests passed`, `verify: ok`.

- [ ] **Step 5: Commit**

```bash
git add -A setup ssh tests/test_links.sh
git commit -m "feat: add bootstrap.sh with per-profile link scripts"
```

---

### Task 5: tmux and neovim clipboard configuration

**Files:**
- Modify: `.tmux.conf` (append a clipboard section)
- Modify: `nvim/init.lua` (append the OSC 52 provider and the Nerd Font flag)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: no new callable interface. `tests/test_links.sh` already asserts
  both files are linked; this task adds content assertions to
  `tests/test_shell_profiles.sh`.

**Why tmux gets these on both profiles:** foot supports OSC 52, so
`set-clipboard on` is a no-op improvement on the desktop rather than something
to gate behind a profile check. Same file, both machines, one behavior.

- [ ] **Step 1: Write the failing test**

Append to `tests/test_shell_profiles.sh`, before the final `echo`:

```bash
# --- tmux clipboard --------------------------------------------------------
tmuxconf=$(cat "$DOTFILES/.tmux.conf")
assert_contains "$tmuxconf" "set -g set-clipboard on" \
  ".tmux.conf enables set-clipboard"
assert_contains "$tmuxconf" "allow-passthrough on" \
  ".tmux.conf enables DCS passthrough"
assert_contains "$tmuxconf" "terminal-features" \
  ".tmux.conf advertises the clipboard terminal feature"

# tmux must actually accept the file.
if command -v tmux >/dev/null 2>&1; then
  out=$(tmux -f "$DOTFILES/.tmux.conf" -L dotfiles-test \
    new-session -d 2>&1) || fail "tmux rejected .tmux.conf: $out"
  got=$(tmux -L dotfiles-test show -gv set-clipboard)
  tmux -L dotfiles-test kill-server 2>/dev/null || true
  assert_eq "on" "$got" "tmux reports set-clipboard on"
else
  echo "  (tmux not installed, skipping live tmux check)"
fi

# --- neovim clipboard ------------------------------------------------------
initlua=$(cat "$DOTFILES/nvim/init.lua")
assert_contains "$initlua" "have_nerd_font" \
  "init.lua sets have_nerd_font"
assert_contains "$initlua" "osc52" \
  "init.lua wires up the OSC 52 clipboard provider"
assert_contains "$initlua" "SSH_TTY" \
  "init.lua gates the OSC 52 provider on an SSH session"

if command -v nvim >/dev/null 2>&1; then
  nvim --headless -c 'quitall' 2>&1 | grep -qi error &&
    fail "nvim reported an error loading the config"
fi
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_shell_profiles.sh`
Expected: FAIL — `.tmux.conf enables set-clipboard`

- [ ] **Step 3: Write minimal implementation**

Append to `.tmux.conf`:

```
# --- clipboard -----------------------------------------------------------
# Copying inside tmux emits an OSC 52 escape, which the terminal drawing the
# pixels turns into a real clipboard write. That is what makes copy work from
# a headless server over ssh, with no X forwarding and no daemon.
# foot supports OSC 52 too, so this is equally correct on the workstations.
set -g set-clipboard on
set -as terminal-features ',*:clipboard'

# Let applications (bin/clip, neovim) send their own OSC 52 through tmux.
set -g allow-passthrough on
```

Append to `nvim/init.lua`:

```lua
-- Emit Nerd Font glyphs. The font itself is only needed on the machine
-- drawing the pixels, never on a remote server -- neovim just sends the
-- codepoints and the local terminal resolves them.
vim.g.have_nerd_font = true

-- Over ssh there is no local clipboard to talk to, so route yanks through
-- OSC 52 and let the terminal put them on the clipboard of whatever machine
-- you are actually sitting at. On the workstations this block is skipped and
-- the normal wl-copy provider is used.
--
-- Paste is deliberately served from the unnamed register rather than read
-- back over OSC 52: most terminals refuse clipboard *reads* for security
-- reasons, so a read-based provider would just hang. Paste into the server
-- with the terminal's own paste instead.
if vim.env.SSH_TTY then
  local osc52 = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = {
    name = "OSC52",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = function()
        return vim.fn.split(vim.fn.getreg(""), "\n")
      end,
      ["*"] = function()
        return vim.fn.split(vim.fn.getreg(""), "\n")
      end,
    },
  }
end
```

`vim.ui.clipboard.osc52` ships with neovim 0.10 and later. The
`common-packages.sh` neovim install is the upstream latest release, so it is
present.

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/run.sh && bash setup/verify.sh`
Expected: `all tests passed`, `verify: ok`.

- [ ] **Step 5: Commit**

```bash
git add .tmux.conf nvim/init.lua tests/test_shell_profiles.sh
git commit -m "feat: route clipboard through OSC 52 for tmux and neovim over ssh"
```

---

### Task 6: Split the package scripts

**Files:**
- Create: `setup/common-packages.sh`
- Create: `setup/desktop-packages.sh`
- Create: `setup/server-packages.sh`
- Delete: `setup/new-sway-packages.sh`, `setup/install-nerd-fonts.sh`,
  `setup/install-extras-p14.sh`

**Interfaces:**
- Consumes: nothing at runtime.
- Produces: three executable scripts. None is run by `bootstrap.sh`; the
  readme sequences them.

These scripts install software, so they are not unit tested — `verify.sh`
syntax-checks them and `test-in-docker.sh` (Task 8) exercises the link path
only. Correctness comes from careful transcription plus a real run.

**Two bugs in the current script to fix during the move:**

1. `sudo apt update && apt install docker-ce ...` — the second command lacks
   `sudo` and fails with a permissions error.
2. `curl ... -o ~/Downloads/awsvpnclient_amd64.debawsvpnclient_amd64.deb` — the
   filename is doubled, so the following `dpkg -i` cannot find the file.

- [ ] **Step 1: Write `setup/common-packages.sh`**

```bash
#!/bin/bash
# Terminal toolchain. Installed on both the desktop and server profiles.
set -euo pipefail

sudo apt update

sudo apt install -y \
  git git-flow tmux curl wget jq gron tree zip unzip ripgrep btop \
  make gpg bash-completion pipx golang ca-certificates gnupg

# --- neovim (upstream release, Debian's is too old for LazyVim) -----------
sudo apt remove -y neovim || true
tmpdir=$(mktemp -d)
curl -Lo "$tmpdir/nvim.tar.gz" \
  https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf "$tmpdir/nvim.tar.gz"
rm -rf "$tmpdir"

# LazyVim starter, only if there is no nvim config yet -- bootstrap.sh links
# our own init.lua into it afterwards.
if [ ! -d "$HOME/.config/nvim/lua/config" ]; then
  git clone https://github.com/LazyVim/starter.git "$HOME/.config/nvim-lazyvim"
  rm -rf "$HOME/.config/nvim-lazyvim/.git"
  mkdir -p "$HOME/.config/nvim"
  cp -rn "$HOME/.config/nvim-lazyvim/." "$HOME/.config/nvim/"
  rm -rf "$HOME/.config/nvim-lazyvim"
fi

# --- lazygit / lazydocker ------------------------------------------------
# `ld` has been aliased to lazydocker for a long time with nothing installing
# it; this is where it comes from now.
go install github.com/jesseduffield/lazygit@latest
go install github.com/jesseduffield/lazydocker@latest

# --- node ----------------------------------------------------------------
if [ ! -d "$HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.7/install.sh | bash
fi
# shellcheck disable=SC1091
. "$HOME/.nvm/nvm.sh"
nvm install 24

# --- zulu 21 jdk ---------------------------------------------------------
curl -s https://repos.azul.com/azul-repo.key |
  sudo gpg --dearmor --yes -o /usr/share/keyrings/azul.gpg
sudo chmod 644 /usr/share/keyrings/azul.gpg
echo "deb [signed-by=/usr/share/keyrings/azul.gpg] https://repos.azul.com/zulu/deb stable main" |
  sudo tee /etc/apt/sources.list.d/zulu.list
sudo apt update
sudo apt install -y zulu21-jdk
sudo ln -sfn /usr/lib/jvm/zulu21-ca-amd64 /usr/lib/jvm/default

# --- docker engine + compose ---------------------------------------------
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
# NOTE: the original script was missing this `sudo`, so it always failed here.
sudo apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"

# --- aws cli v2 ----------------------------------------------------------
tmpdir=$(mktemp -d)
curl -sS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o "$tmpdir/awscliv2.zip"
unzip -q -d "$tmpdir" "$tmpdir/awscliv2.zip"
sudo "$tmpdir/aws/install" --update
rm -rf "$tmpdir"

# --- github cli ----------------------------------------------------------
sudo apt install -y gh

# --- claude code ---------------------------------------------------------
curl -fsSL https://claude.ai/install.sh | bash

echo
echo "common packages installed."
echo "log out and back in for the docker group to take effect."
```

- [ ] **Step 2: Write `setup/desktop-packages.sh`**

```bash
#!/bin/bash
# Everything that needs a display. Desktop profile only.
set -euo pipefail

sudo apt update

# --- sway session --------------------------------------------------------
sudo apt install -y \
  sway swayidle swaylock swaybg foot \
  i3status wmenu wofi xwayland dex mako-notifier \
  pipewire pipewire-pulse wireplumber pulseaudio-utils \
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
  grim slurp swappy wl-clipboard brightnessctl pulsemixer \
  network-manager network-manager-gnome mate-polkit \
  thermald fonts-dejavu firefox-esr thunar gsimplecal \
  kdiff3 ranger

# needed for bin/swaycwd
sudo apt install -y jq gron

# --- JetBrains Mono Nerd Font --------------------------------------------
# Fonts belong on the machine that draws the pixels, which is this one.
# The EC2 box never needs them: neovim there emits the codepoints and this
# terminal resolves the glyphs.
mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNF"
(
  cd "$HOME/.local/share/fonts/JetBrainsMonoNF"
  wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  unzip -oq JetBrainsMono.zip
  rm JetBrainsMono.zip
)
fc-cache -f
fc-match "JetBrainsMono Nerd Font Mono"

# --- 1password -----------------------------------------------------------
curl -sS https://downloads.1password.com/linux/keys/1password.asc |
  sudo gpg --dearmor --yes --output /usr/share/keyrings/1password-archive-keyring.gpg
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' |
  sudo tee /etc/apt/sources.list.d/1password.list
sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol |
  sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol >/dev/null
sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
curl -sS https://downloads.1password.com/linux/keys/1password.asc |
  sudo gpg --dearmor --yes --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
sudo apt update
sudo apt install -y 1password

# --- resilio sync --------------------------------------------------------
mkdir -p "$HOME/Downloads" "$HOME/MyApps/resilio-sync"
wget -qP "$HOME/Downloads" \
  https://download-cdn.resilio.com/stable/linux/x64/0/resilio-sync_x64.tar.gz
tar -xzf "$HOME/Downloads/resilio-sync_x64.tar.gz" -C "$HOME/MyApps/resilio-sync/"

# --- aws vpn client ------------------------------------------------------
# NOTE: the original script doubled the filename here, so the dpkg below could
# never find the file.
curl -fsSL https://d20adtppz83p9s.cloudfront.net/GTK/latest/awsvpnclient_amd64.deb \
  -o "$HOME/Downloads/awsvpnclient_amd64.deb"
sudo dpkg -i "$HOME/Downloads/awsvpnclient_amd64.deb" || sudo apt install -yf
sudo systemctl --now enable awsvpnclient

# --- dbeaver -------------------------------------------------------------
wget -qO "$HOME/Downloads/dbeaver-ce.deb" \
  https://dbeaver.io/files/dbeaver-ce-latest-linux-x86_64.deb
sudo apt install -y "$HOME/Downloads/dbeaver-ce.deb"

# --- p14 laptop firmware -------------------------------------------------
if [ "$(hostname)" = "shadowlt" ]; then
  sudo apt install -y firmware-atheros firmware-misc-nonfree
  echo "firmware installed -- reboot when convenient."
fi

echo
echo "desktop packages installed. See docs/desktop-notes.md for the"
echo "AWS Client VPN DNS fix, power management, and Slack screen sharing."
```

- [ ] **Step 3: Write `setup/server-packages.sh`**

```bash
#!/bin/bash
# Headless server profile only. Everything else comes from common-packages.sh.
set -euo pipefail

sudo apt update

# mosh survives a laptop lid close far better than plain ssh.
sudo apt install -y mosh locales

# Back the UTF-8 export in shell/profile.server with a generated locale.
# Without this, LANG=en_US.UTF-8 is set but not valid, and glyphs still break.
sudo sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen

# --- tailscale -----------------------------------------------------------
# Network layer only. `tailscale up` is a separate, interactive step:
#   ./setup/server-tailscale.sh
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi

echo
echo "server packages installed. Next:"
echo "  ./setup/server-tailscale.sh"
```

- [ ] **Step 4: Remove the superseded scripts and verify**

```bash
git rm setup/new-sway-packages.sh setup/install-nerd-fonts.sh \
  setup/install-extras-p14.sh
chmod +x setup/*.sh
bash setup/verify.sh
bash tests/run.sh
```

Expected: `verify: ok` and `all tests passed`. If `shellcheck` is installed it
must also pass at `--severity=warning`; fix anything it flags before
committing.

- [ ] **Step 5: Commit**

```bash
git add -A setup
git commit -m "refactor: split package installation by profile

Also fixes two long-standing bugs carried over from new-sway-packages.sh:
a missing sudo on the docker install, and a doubled filename in the AWS VPN
Client download."
```

---

### Task 7: Tailscale and SSH helper scripts

**Files:**
- Create: `setup/server-tailscale.sh`
- Create: `setup/server-ssh.sh`

**Interfaces:**
- Consumes: `tailscale` from `setup/server-packages.sh`.
- Produces:
  - `setup/server-tailscale.sh` — runs `tailscale up`, using `$TS_AUTHKEY`
    when set, otherwise printing the auth URL. Exits 1 with a clear message if
    `tailscale` is not installed.
  - `setup/server-ssh.sh --generate-key` — creates
    `~/.ssh/id_ed25519_agentbox`, appends a `Host github.com` block to
    `~/.ssh/config` selecting it, prints the public key. Without the flag it
    prints usage and exits 2. Never overwrites an existing key.

**Why `--ssh` is not passed to `tailscale up`:** Tailscale SSH replaces `sshd`
with Tailscale's own SSH server, and agent-forwarding parity there is
unverified. Using Tailscale purely for connectivity and connecting to stock
`sshd` over the tailnet address keeps standard SSH semantics — agent
forwarding, `scp`, `rsync`, `mosh` — at no cost. Adding `--ssh` later is one
word.

- [ ] **Step 1: Write `setup/server-tailscale.sh`**

```bash
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
```

- [ ] **Step 2: Write `setup/server-ssh.sh`**

```bash
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

if [ -f "$KEY" ]; then
  echo "$KEY already exists, leaving it alone."
else
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
```

Note `IdentitiesOnly yes`: without it, ssh offers every key the forwarded
agent holds before this one and can trip GitHub's authentication-attempt
limit.

- [ ] **Step 3: Verify**

Run: `chmod +x setup/server-tailscale.sh setup/server-ssh.sh && bash setup/verify.sh`
Expected: `verify: ok`.

Then check the usage paths behave, without generating anything:

```bash
bash setup/server-ssh.sh; echo "exit=$?"      # expect usage text, exit=2
bash setup/server-ssh.sh --wrong; echo "exit=$?"  # expect usage text, exit=2
```

- [ ] **Step 4: Commit**

```bash
git add setup/server-tailscale.sh setup/server-ssh.sh
git commit -m "feat: add tailscale and server ssh key helpers"
```

---

### Task 8: Docker integration test for the server profile

Proves the server profile works on a clean Debian 13 before an EC2 instance
exists. Links only — package installation is slow and is exercised by real
use.

**Files:**
- Create: `setup/test-in-docker.sh`

**Interfaces:**
- Consumes: `setup/bootstrap.sh`, `shell/profile.server`, `bin/clip`.
- Produces: `setup/test-in-docker.sh` — exit 0 iff every assertion passes
  inside a `debian:13` container.

- [ ] **Step 1: Write the test script**

```bash
#!/bin/bash
# Run the server profile end-to-end on a clean Debian 13.
#
# Links only: package installation takes many minutes and is covered by
# actually using the box. What this proves is that on a machine with nothing
# on it, bootstrap.sh server produces resolvable symlinks and a login shell
# with the right environment.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v docker >/dev/null 2>&1 || {
  echo "docker is required for this test" >&2
  exit 1
}

docker run --rm -i \
  -v "$DOTFILES:/src:ro" \
  debian:13 bash -s <<'CONTAINER'
set -euo pipefail

apt-get update -qq
apt-get install -y -qq git tmux coreutils >/dev/null

useradd -m -s /bin/bash jkurtz
mkdir -p /home/jkurtz/wd
cp -r /src /home/jkurtz/wd/dotfiles
chown -R jkurtz:jkurtz /home/jkurtz

su - jkurtz -c 'bash -euo pipefail -s' <<'USER'
set -euo pipefail
cd ~/wd/dotfiles

fail() { echo "FAIL: $1" >&2; exit 1; }

# 1. bootstrap succeeds
./setup/bootstrap.sh server || fail "bootstrap.sh server exited non-zero"

# 2. every symlink we created resolves
for link in ~/.profile ~/.profile.local ~/.bash_aliases ~/.gitconfig \
  ~/.tmux.conf ~/.local/bin/clip ~/.config/nvim/init.lua \
  ~/.config/nvim/lua/plugins/blink.lua; do
  [ -L "$link" ] || fail "$link is not a symlink"
  [ -e "$link" ] || fail "$link points at a nonexistent target"
done

# 3. BROWSER=echo reaches a login shell
got=$(bash -lc 'printf "%s" "$BROWSER"')
[ "$got" = "echo" ] || fail "BROWSER is '$got', expected 'echo'"

# 4. no agent present -> no SSH_AUTH_SOCK, and no error
got=$(bash -lc 'printf "%s" "${SSH_AUTH_SOCK:-}"') ||
  fail "login shell errored while evaluating SSH_AUTH_SOCK"
[ -z "$got" ] || fail "SSH_AUTH_SOCK is '$got' with no agent running"

# 5. a UTF-8 locale is exported
got=$(bash -lc 'printf "%s" "$LANG"')
case "$got" in
*UTF-8 | *utf8 | *UTF8) ;;
*) fail "LANG is '$got', expected a UTF-8 locale" ;;
esac

# 6. tmux accepts the config and reports set-clipboard on
tmux -f ~/.tmux.conf -L ci new-session -d
got=$(tmux -L ci show -gv set-clipboard)
tmux -L ci kill-server
[ "$got" = "on" ] || fail "tmux set-clipboard is '$got', expected 'on'"

# 7. clip emits the right bytes in both tmux states
ESC=$(printf '\033')
BEL=$(printf '\a')
printf 'hello' | env -u WAYLAND_DISPLAY -u TMUX CLIP_TTY=/tmp/bare ~/.local/bin/clip
expected="${ESC}]52;c;aGVsbG8=${BEL}"
[ "$(cat /tmp/bare)" = "$expected" ] || fail "clip emitted the wrong bare OSC 52"

printf 'hello' | env -u WAYLAND_DISPLAY TMUX=fake CLIP_TTY=/tmp/wrapped ~/.local/bin/clip
expected="${ESC}Ptmux;${ESC}${ESC}]52;c;aGVsbG8=${BEL}${ESC}\\"
[ "$(cat /tmp/wrapped)" = "$expected" ] ||
  fail "clip emitted the wrong tmux-wrapped OSC 52"

# 8. no sway config was created
for p in ~/.config/sway ~/.config/foot ~/.local/bin/swaycwd; do
  [ -e "$p" ] && fail "server profile created $p"
done

echo "server profile: all container checks passed"
USER
CONTAINER
```

Assertion 7 calls `~/.local/bin/clip` by absolute path deliberately: it tests
the script itself rather than the `PATH` wiring, which assertion 2 already
covers.

- [ ] **Step 2: Run it**

Run: `chmod +x setup/test-in-docker.sh && ./setup/test-in-docker.sh`
Expected: `server profile: all container checks passed`, exit 0.

If docker is not available on the machine running this plan, say so explicitly
in the task report rather than marking the task done — this test is the main
evidence the server profile works.

- [ ] **Step 3: Commit**

```bash
git add setup/test-in-docker.sh
git commit -m "test: verify the server profile on a clean Debian 13 container"
```

---

### Task 9: Documentation

**Files:**
- Modify: `readme.md` (rewrite)
- Create: `docs/desktop-notes.md` (via `git mv setup/new-sway-followup.md`)

**Interfaces:**
- Consumes: every script from Tasks 4, 6, 7.
- Produces: no code interface.

- [ ] **Step 1: Move the desktop troubleshooting notes**

```bash
mkdir -p docs
git mv setup/new-sway-followup.md docs/desktop-notes.md
```

Add this heading at the top of `docs/desktop-notes.md`:

```markdown
# Desktop Follow-Up Notes

Things that need doing by hand on a sway workstation after
`setup/desktop-packages.sh`. None of this applies to the server profile.
```

- [ ] **Step 2: Rewrite `readme.md`**

```markdown
# dotfiles

Two profiles from one checkout:

| Profile | Machines | What it configures |
|---|---|---|
| `desktop` | `shadowws`, `shadowlt` | sway session, foot, mako, swappy, i3status, GUI apps |
| `server` | headless Debian 13 (EC2) | terminal only: shell, tmux, neovim, ssh agent, Tailscale |

Everything both profiles need — bash, git, tmux, neovim, docker, the language
runtimes — is shared. `bootstrap.sh` picks which extra set gets linked.

## Desktop

```
mkdir -p ~/wd
git clone https://github.com/jamiekurtz/dotfiles.git ~/wd/dotfiles
cd ~/wd/dotfiles
./setup/common-packages.sh
./setup/desktop-packages.sh
./setup/bootstrap.sh desktop
. ~/.profile
```

Then see `docs/desktop-notes.md` for the AWS Client VPN DNS fix, laptop power
management, and Slack screen sharing.

Before launching sway, verify the config:

```
sway -C -c ~/.config/sway/config
sway -C -c ~/.config/sway/config.common
sway -C -c ~/.config/sway/config.d/p14.conf
sway -C -c ~/.config/sway/config.d/meerkat.conf
```

The harmless error `gpu: amdgpu_cs_ctx_create2 failed` is expected.

`.profile` execs sway on tty1. `touch ~/.no-sway` disables that; remove the
file to restore it.

## Server (headless Debian 13 on EC2)

Assumes a `jkurtz` user with sudo already exists — creating it is instance
provisioning, not this repo's job.

```
mkdir -p ~/wd
git clone https://github.com/jamiekurtz/dotfiles.git ~/wd/dotfiles
cd ~/wd/dotfiles
./setup/common-packages.sh
./setup/server-packages.sh
./setup/bootstrap.sh server
./setup/server-tailscale.sh
. ~/.profile
```

`server-tailscale.sh` prints an auth URL to paste into a browser on whatever
machine you are sitting at. `TS_AUTHKEY=tskey-auth-... ./setup/server-tailscale.sh`
does it unattended.

Then on your workstation, put the box's MagicDNS name into `ssh/agentbox.conf`
and add this as the **first** line of `~/.ssh/config`:

```
Include config.d/*
```

`ssh agentbox` then works from anywhere on the tailnet, with your SSH agent
forwarded.

### Copy and paste from the server

Copying in tmux or neovim on the server lands in the clipboard of the machine
you are sitting at, over OSC 52 — no X forwarding, no daemon. `bin/clip` does
the same for shell output:

```
pwd | clip
cat some-file | clip
```

Pasting *into* the server uses your terminal's own paste. Most terminals refuse
clipboard reads, so there is deliberately no OSC 52 paste path.

### Git pushes

Interactive work uses your forwarded agent. `shell/profile.server` keeps
`~/.ssh/auth_sock` pointed at the live socket, so tmux panes survive a
disconnect and reconnect.

Agents that keep running *after* you disconnect have no forwarded agent, so
they need a key on the box:

```
./setup/server-ssh.sh --generate-key
```

That prints a public key to add at https://github.com/settings/keys.

### herdr

Installed from the client. Nothing is needed on the server for it.

## Tests

```
./setup/verify.sh          # syntax + shellcheck over every script
bash tests/run.sh          # unit tests
./setup/test-in-docker.sh  # server profile on a clean debian:13
```

## Layout

```
shell/     profile.common + profile.desktop/server, aliases.common
bin/       clip (both profiles), swaycwd (desktop)
setup/     bootstrap.sh + per-profile package and link scripts
ssh/       agentbox.conf, the client-side Host entry
sway/ foot/ mako/ swappy/ i3status/ i3/ picom/   desktop config
nvim/      init.lua + plugin overrides
tests/     shell test suite
docs/      desktop notes, specs, plans
```
```

- [ ] **Step 3: Verify**

Run: `bash setup/verify.sh && bash tests/run.sh`
Expected: `verify: ok`, `all tests passed`.

Then confirm every path and script name mentioned in `readme.md` exists:

```bash
grep -oE '(setup|tests|shell|bin|ssh|docs)/[A-Za-z0-9._/-]+' readme.md |
  sort -u | while read -r p; do
    [ -e "$p" ] || echo "readme references missing path: $p"
  done
```

Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add -A readme.md docs
git commit -m "docs: rewrite readme for the desktop and server profiles"
```

---

### Task 10: Desktop regression check

The desktop machines must land in the state they were in before this branch.
This task is manual and runs on a real workstation.

**Files:** none.

**Interfaces:** none.

- [ ] **Step 1: Re-link on the workstation**

```bash
cd ~/wd/dotfiles
git checkout feature/headless-server-profile
./setup/bootstrap.sh desktop
```

- [ ] **Step 2: Confirm the sway config still validates**

```bash
sway -C -c ~/.config/sway/config
```

Expected: no errors beyond the known `gpu: amdgpu_cs_ctx_create2 failed`.

- [ ] **Step 3: Confirm the links match what was there before**

```bash
for l in ~/.profile ~/.profile.local ~/.bash_aliases ~/.gitconfig ~/.tmux.conf \
  ~/.config/sway/config ~/.config/sway/config.common ~/.config/sway/config.d \
  ~/.config/foot/foot.ini ~/.config/mako/config ~/.config/swappy/config \
  ~/.config/i3status/config ~/.local/bin/swaycwd ~/.local/bin/clip \
  ~/.config/nvim/init.lua ~/.config/xdg-desktop-portal/sway-portals.conf; do
  printf '%-55s -> %s\n' "$l" "$(readlink -f "$l" || echo MISSING)"
done
```

Expected: every line resolves; none says MISSING.

- [ ] **Step 4: Confirm the session and clipboard still work**

- Log out and back in on tty1; sway starts.
- In foot: `pwd | clip`, then paste into another application. The path appears.
- In neovim: yank a line with `"+yy`, paste elsewhere. It appears.

- [ ] **Step 5: Report**

No commit. Report which checks passed and any that did not, verbatim.

---

## Self-Review

**Spec coverage.** Every section of the spec maps to a task: repo layout →
Tasks 3/4/6/9; profile selection → Task 4; shell split → Task 3; clipboard →
Tasks 2 and 5; transport, agent, and git credentials → Tasks 3 (agent socket)
and 7 (Tailscale, keys, `agentbox.conf` in Task 4); package split → Task 6;
link scripts → Task 4; verification → Tasks 1, 8, and 10; documentation →
Task 9. The two spec deviations are stated at the top of the File Structure
section with reasons.

**Placeholders.** None. `CHANGEME` appears once, in `ssh/agentbox.conf`, where
it is the intended value — the MagicDNS name does not exist until
`tailscale up` has run, and the readme says to fill it in.

**Type consistency.** `assert_eq`, `assert_contains`, `assert_link`, and `fail`
are defined in Task 1 and used with those names and argument orders in Tasks 2,
3, 4, and 5. `$DOTFILES`, `$CLIP_TTY`, `$HOSTNAME_OVERRIDE`, and `$TS_AUTHKEY`
are used consistently throughout. `~/.profile.local` is the profile hook in
every task that touches it; `~/.bash_aliases.local` is sourced by
`aliases.common` but deliberately never created by a link script.

**Consistency of `clip`.** `clip` is a script (`bin/clip`), symlinked to
`~/.local/bin/clip`, never an alias. Task 3's test asserts the absence of an
`alias clip=` line, Task 4 asserts the symlink exists, and Task 8 invokes it
by absolute path. The old `alias clip="xclip ..."` is deleted in Task 3.

# Headless Debian 13 Server Profile

Date: 2026-09-05
Branch: `feature/headless-server-profile`

## Goal

Let this repo configure two kinds of machine from one checkout:

- **desktop** — the existing sway workstations (`shadowws`, `shadowlt`), unchanged in behavior.
- **server** — a headless Debian 13 EC2 instance running multiple Claude Code
  agents, reached over Tailscale and driven through herdr remote sessions from
  the client.

Today every config is desktop-shaped: `.profile` runs `exec sway`, the single
link script symlinks compositor configs unconditionally, and one package script
installs the whole GUI stack.

## Non-goals

- Provisioning the EC2 instance (AMI, security groups, IAM role, creating the
  `jkurtz` user). That is cloud-init / Terraform work outside this repo. The
  scripts assume you are already logged in as `jkurtz` with sudo.
- Installing or configuring herdr. It is installed from the client and needs
  nothing on the server.
- Supporting distributions other than Debian 13.

## Repo layout

Tool config directories keep their current names and paths. Shell files move
into `shell/`; the setup scripts split three ways.

```
dotfiles/
  .gitconfig                      profile-neutral, stays at root
  .tmux.conf                      profile-neutral, stays at root
  shell/
    profile.common   profile.desktop   profile.server
    aliases.common
  bin/
    swaycwd                       desktop only
    clip                          both profiles
  sway/ foot/ mako/ swappy/ i3/ i3status/ picom/ xdg-desktop-portal/
  nvim/
  ssh/
    agentbox.conf                 client-side Host entry
  setup/
    bootstrap.sh
    common-packages.sh   common-links.sh
    desktop-packages.sh  desktop-links.sh
    server-packages.sh   server-links.sh
    server-tailscale.sh  server-ssh.sh
    verify.sh            test-in-docker.sh
  docs/superpowers/specs/
```

Removed: `setup/new-sway-links.sh`, `setup/new-sway-packages.sh`,
`setup/new-i3-links.sh`, `setup/install-extras-p14.sh`,
`setup/install-nerd-fonts.sh` — their contents are redistributed into the
scripts above. `setup/new-sway-followup.md` folds into `readme.md`.
`.profile` and `.bash_aliases` move to `shell/` (git mv, history preserved).

## Profile selection

Explicit, never guessed:

```
./setup/bootstrap.sh desktop
./setup/bootstrap.sh server
```

`bootstrap.sh` requires the argument, exits with usage otherwise. It writes the
profile name to `~/.dotfiles-profile`, then runs `common-links.sh` followed by
`<profile>-links.sh`. Package installation is deliberately a separate,
manually-invoked step (`common-packages.sh` then `<profile>-packages.sh`) so
re-linking is always fast and safe to repeat.

Hostname-based dispatch survives only where it already exists and still makes
sense: `desktop-links.sh` picks the per-host sway config for `shadowws` vs
`shadowlt`.

## Shell split

`common-links.sh` creates:

| link | target |
|---|---|
| `~/.profile` | `shell/profile.common` |
| `~/.bash_aliases` | `shell/aliases.common` |

`<profile>-links.sh` creates:

| link | target |
|---|---|
| `~/.profile.local` | `shell/profile.<profile>` |

Each common file ends by sourcing its `.local` counterpart if present, so the
common file never has to resolve the repo path:

```sh
[ -f "$HOME/.profile.local" ] && . "$HOME/.profile.local"
```

**`profile.common`** — the existing `path_add` block, `EDITOR=nvim`,
`JAVA_HOME`, `GOPATH`, `LEFTHOOK=0`. Both profiles install the same runtimes,
so these are shared.

**`profile.desktop`** — the `exec sway` block, verbatim, including the
`~/.no-sway` escape hatch.

**`profile.server`** —

- `export BROWSER=echo` so OAuth device flows (Claude Code, `gh auth login`,
  `tailscale up`) print their URL instead of failing to launch a browser.
- `export LANG=en_US.UTF-8` / `LC_ALL=en_US.UTF-8`, guarded so an already-set
  UTF-8 locale is left alone. Debian cloud images frequently boot with `LANG`
  unset, which renders Nerd Font glyphs and box-drawing characters as
  mojibake in neovim and lazygit. `server-packages.sh` runs `locale-gen` for
  that locale so the export is backed by a generated locale.
- The SSH_AUTH_SOCK stabilization below.
- No compositor launch, so a stray tty login on the server cannot try to
  start sway.

**Aliases are not split by profile.** Every alias in the current
`.bash_aliases` is a terminal or docker helper, and both profiles install the
same terminal toolchain, so a per-profile alias file would be machinery for a
distinction that does not exist. There is one `shell/aliases.common`, linked to
`~/.bash_aliases`, holding all of them: `bc`, `psg`, `vim`, `ll`, `clip`, `lg`,
`ld`, `rng`, `mongotools`, `rc-run`, `jup-run`, `browsy-run`, `py-run`,
`prism-run`, `ate-run`, `whatsmyip`, the git helpers (`git-clean-feature`,
`gd`, `git-diff-master`, `git-diff-develop`), the `cd*` project shortcuts, and
`PS1`.

It still ends with the `.local` hook below, so a profile-specific alias file
can be added later without restructuring anything:

```sh
[ -f "$HOME/.bash_aliases.local" ] && . "$HOME/.bash_aliases.local"
```

`shell/aliases.desktop` and `shell/aliases.server` are not created, and no link
script creates `~/.bash_aliases.local`.

**Bug found while auditing the aliases:** `ld` is aliased to `lazydocker`, but
nothing in the repo installs it — the alias is broken on both existing
machines. `common-packages.sh` gains a `go install
github.com/jesseduffield/lazydocker@latest`, matching the lazygit pattern.

## Clipboard over tmux and SSH

Three coordinated pieces.

**tmux** (`.tmux.conf`, applies to both profiles — foot supports OSC 52, so
these lines are harmless on the desktop):

```
set -g set-clipboard on
set -as terminal-features ',*:clipboard'
set -g allow-passthrough on
```

**neovim** (`nvim/init.lua`) — an OSC 52 provider, active only over SSH so the
desktop keeps using `wl-copy`:

```lua
if vim.env.SSH_TTY then
  local osc52 = require('vim.ui.clipboard.osc52')
  vim.g.clipboard = {
    name = 'OSC52',
    copy = { ['+'] = osc52.copy('+'), ['*'] = osc52.copy('*') },
    paste = {
      ['+'] = function() return vim.fn.split(vim.fn.getreg(''), '\n') end,
      ['*'] = function() return vim.fn.split(vim.fn.getreg(''), '\n') end,
    },
  }
end
```

Paste-back over OSC 52 is deliberately not wired up: most terminals refuse
clipboard *reads* for security reasons. Pasting into the server uses the
terminal's own paste, which works normally.

`init.lua` also sets `vim.g.have_nerd_font = true` unconditionally, so neovim
emits Nerd Font glyphs on both profiles.

**`bin/clip`** — replaces the current `alias clip="xclip -selection clipboard"`,
which is broken today (the desktops run Wayland, not X). The script reads
stdin and:

- writes via `wl-copy` when `$WAYLAND_DISPLAY` is set;
- otherwise emits an OSC 52 sequence to `/dev/tty`, wrapping it in a
  `\033Ptmux;...\033\\` DCS passthrough when `$TMUX` is set, since a bare
  OSC 52 written inside tmux is swallowed.

`aliases.common` aliases `clip` to the script.

## Transport, SSH agent, and git credentials

**Tailscale as the network layer.** `server-packages.sh` installs `tailscaled`
from the official install script. `server-tailscale.sh` runs `tailscale up`,
using `$TS_AUTHKEY` when set and otherwise printing the auth URL to the
terminal (which `BROWSER=echo` guarantees).

`--ssh` is deliberately **not** used. Tailscale SSH substitutes its own SSH
server for `sshd`, and agent-forwarding parity there is unverified. Using
Tailscale purely for connectivity and connecting to stock `sshd` over the
tailnet address keeps standard SSH semantics — agent forwarding, `scp`,
`rsync`, `mosh` — with no downside. Adding `--ssh` later is a one-line change.

**Agent forwarding that survives tmux reattach.** A forwarded agent socket path
changes on every new SSH connection, so long-lived tmux panes hold a dead path.
`profile.server` stabilizes it:

```sh
if [ -S "$SSH_AUTH_SOCK" ] && [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/auth_sock" ]; then
  ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/auth_sock"
fi
[ -S "$HOME/.ssh/auth_sock" ] && export SSH_AUTH_SOCK="$HOME/.ssh/auth_sock"
```

Panes export the stable path; each new login re-points the symlink, and
existing panes start working again without being restarted.

**Unattended fallback.** `server-ssh.sh --generate-key` creates
`~/.ssh/id_ed25519_agentbox`, appends a `Host github.com` block selecting it,
and prints the public key to add to GitHub. Opt-in: agents that keep running
after you disconnect cannot use a forwarded agent, but a key on the server is
not something to create silently.

**Client side.** `ssh/agentbox.conf` is linked to `~/.ssh/config.d/agentbox.conf`
by `desktop-links.sh` and holds the `Host agentbox` entry (tailnet hostname,
`User jkurtz`, `ForwardAgent yes`, `ServerAliveInterval 30`). Bootstrap never
rewrites an existing `~/.ssh/config`; it prints a one-line instruction to add
`Include config.d/*` at the top.

## Package split

**`common-packages.sh`** — the terminal toolchain, installed on both profiles:

- apt: `git git-flow tmux curl wget jq gron tree zip unzip ripgrep btop make gpg
  bash-completion pipx golang ca-certificates gnupg`
- neovim from the upstream tarball into `/opt`, plus LazyVim starter
- `lazygit` and `lazydocker` via `go install`
- nvm + Node 24
- Zulu 21 JDK, with the `/usr/lib/jvm/default` symlink
- Docker CE + compose plugin, `usermod -aG docker`
- AWS CLI v2
- GitHub CLI (`gh`)
- Claude Code

**`desktop-packages.sh`** — everything requiring a display: sway, swayidle,
swaylock, swaybg, foot, i3status, wmenu, wofi, xwayland, dex, mako, pipewire
stack, xdg-desktop-portal{,-wlr,-gtk}, grim, slurp, swappy, wl-clipboard,
brightnessctl, pulsemixer, network-manager{,-gnome}, mate-polkit, thermald,
fonts-dejavu, firefox-esr, thunar, gsimplecal, kdiff3, ranger, JetBrains Mono
Nerd Font, 1Password, DBeaver, Resilio Sync, AWS VPN Client, and the
`firmware-atheros firmware-misc-nonfree` P14 extras (guarded by hostname).

**`server-packages.sh`** — `tailscale`, `mosh`, and `locales` plus a
`locale-gen en_US.UTF-8` to back the locale export in `profile.server`.

**Nerd fonts stay desktop-only.** Glyph rasterization happens entirely in the
terminal drawing the pixels. Neovim on the server emits Nerd Font *codepoints*
over the wire; the local terminal — foot on the workstation, or whatever herdr
renders into — resolves them against its own fontconfig. Installing JetBrains
Mono NF on the server would consume disk and change nothing, because nothing
server-side rasterizes text. What the server does need is `have_nerd_font` set
in neovim and a UTF-8 locale, both covered above.

Two bugs carried in the current script are fixed during the move:

1. `sudo apt update && apt install docker-ce ...` — the second command is
   missing `sudo` and fails.
2. The AWS VPN Client download writes to
   `awsvpnclient_amd64.debawsvpnclient_amd64.deb` (filename doubled), so the
   following `dpkg -i` cannot find the file.

## Link scripts

**`common-links.sh`** — `.gitconfig`, `.tmux.conf`, `shell/profile.common`
(to `~/.profile`), `shell/aliases.common` (to `~/.bash_aliases`), `nvim/init.lua`, `nvim/lua/plugins/blink.lua`,
`bin/clip`.

**`desktop-links.sh`** — `sway/config.common`, `sway/config.d`, the per-host
`sway/config-for-*` selection, `foot/foot.ini`, `mako/config`, `swappy/config`,
`i3status/config`, `bin/swaycwd`, `xdg-desktop-portal/sway-portals.conf` (plus
the portal `pkill` restart), `~/.profile.local`, and
`~/.ssh/config.d/agentbox.conf`.

**`server-links.sh`** — `~/.profile.local`, and `mkdir -p ~/.ssh` with correct
`0700` permissions.

All scripts use `ln -sfn` and `mkdir -p`, and are safe to re-run.

## Verification

**`setup/verify.sh`** — runs `bash -n` over every script in `setup/` and
`shell/`, and `shellcheck` on each when it is installed. Cheap, runs anywhere.

**`setup/test-in-docker.sh`** — runs the server profile end to end inside a
`debian:13` container, linking only (packages are skipped; they are slow and
already exercised by real use). Asserts:

1. `bootstrap.sh server` exits zero.
2. Every symlink under `$HOME` created by the run resolves to an existing file.
3. `bash -lc 'echo $BROWSER'` prints `echo`.
4. `bash -lc 'echo $SSH_AUTH_SOCK'` does not error with no agent present.
5. `bash -lc 'echo $LANG'` prints a UTF-8 locale.
6. `tmux -f .tmux.conf new-session -d` starts and `tmux show -g set-clipboard`
   reports `on`.
7. `bin/clip` with `TMUX` set and unset emits the expected byte sequences.

This gives evidence the server profile works before an EC2 instance exists.

**Manual desktop check** — re-run `./setup/bootstrap.sh desktop` on `shadowlt`,
confirm `sway -C -c ~/.config/sway/config` still validates and the session
starts.

## Documentation

`readme.md` is rewritten with a section per profile: the desktop flow as it
exists today (updated for the new script names), and a server flow covering
clone → `common-packages.sh` → `server-packages.sh` → `bootstrap.sh server` →
`server-tailscale.sh` → optional `server-ssh.sh --generate-key`, plus notes on
the `Include config.d/*` line and how OSC 52 copy behaves.

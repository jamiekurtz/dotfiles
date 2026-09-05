# dotfiles

Two profiles from one checkout:

| Profile | Machines | What it configures |
|---|---|---|
| `desktop` | `shadowws`, `shadowlt` | sway session, foot, mako, swappy, i3status, GUI apps |
| `server` | headless Debian 13 (EC2) | terminal only: shell, tmux, neovim, ssh agent, Tailscale |

Everything both profiles need — bash, git, tmux, neovim, docker, the language
runtimes — is shared. `bootstrap.sh` picks which extra set gets linked, but it
is symlinks only; packages are a separate step below.

## Desktop

```
touch ~/.no-sway  # delete this file when ready to auto-launch sway
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

`bootstrap.sh server` warns to stderr if `~/.bashrc` is missing or doesn't
source `~/.bash_aliases` — this repo only owns `~/.bash_aliases` itself, so
if the `jkurtz` user was created without `/etc/skel` (common with cloud-init),
nothing else will source it and the prompt and aliases will silently never
load. Follow the warning's instructions if you see it.

Then on your workstation, edit `~/.ssh/config.d/agentbox.conf` — your own
copy, not the repo's template — and replace the `CHANGEME` placeholder in
the `HostName` line with the box's MagicDNS name — run `tailscale status` on
either machine to find it. Add this as the **first** line of
`~/.ssh/config`:

```
Include config.d/*
```

(`setup/desktop-links.sh` copies the repo's `ssh/agentbox.conf.template` to
`~/.ssh/config.d/agentbox.conf` the first time it runs, and never touches
that copy again, so your edits survive re-running bootstrap. It prints the
`Include` reminder above if your `~/.ssh/config` doesn't already have it.)

`ssh agentbox` then works from anywhere on the tailnet, with your SSH agent
forwarded.

### Copy and paste from the server

Copying in tmux or neovim on the server lands in the clipboard of the machine
you are sitting at, over OSC 52 — no X forwarding, no daemon. `bin/clip` does
the same for shell output, reading from stdin:

```
pwd | clip
cat some-file | clip
```

Pasting *into* the server uses your terminal's own paste. Most terminals
refuse clipboard reads over OSC 52, so there is deliberately no paste path
here — this is a one-way (server-to-client) mechanism only.

### Git pushes

Interactive work uses your forwarded agent. `shell/profile.server` keeps
`~/.ssh/auth_sock` pointed at the live socket, so tmux panes survive a
disconnect and reconnect.

Agents that keep running *after* you disconnect have no forwarded agent, so
they need a key on the box. This is opt-in — nothing generates a private key
on the server unless you ask:

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

`test-in-docker.sh` ships only what's committed to git into the container —
it warns (but doesn't stop) if your working tree has uncommitted changes,
since those won't be exercised by the test.

## Layout

```
shell/     profile.common + profile.desktop/server, aliases.common
bin/       clip (both profiles), swaycwd (desktop)
setup/     bootstrap.sh + per-profile package and link scripts
ssh/       agentbox.conf.template, the client-side Host entry (copied, not linked)
sway/ foot/ mako/ swappy/ i3status/   desktop config
nvim/      init.lua + plugin overrides
tests/     shell test suite
docs/      desktop notes, specs, plans
```

`i3/` and `picom/` are legacy from the pre-sway setup. They are still
tracked but linked by no profile.

# dotfiles

Two profiles from one checkout:

| Profile | Machines | What it configures |
|---|---|---|
| `desktop` | `shadowws`, `shadowlt` | sway session, foot, mako, swappy, i3status, GUI apps |
| `server` | headless Debian 13 (EC2) | terminal only: shell, tmux, neovim, ssh agent, Tailscale |

Everything both profiles need — bash, git, tmux, neovim, docker, the language
runtimes — is shared. `bootstrap.sh` picks which extra set gets linked, but it
is symlinks only; packages are a separate step below.

`common-packages.sh` installs git, but you need git before that to clone this
repo at all, so both quickstarts below start by apt-installing it. A fresh
Debian 13 cloud image has neither git nor a checkout to run scripts from.

## Desktop

```
touch ~/.no-sway  # delete this file when ready to auto-launch sway
sudo apt update && sudo apt install -y git   # just to clone; scripts handle the rest
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

Assumes a user with sudo already exists — creating it is instance
provisioning, not this repo's job. The name doesn't matter: every setup script
derives its paths from `$HOME` and its own location, so `admin` (the Debian
cloud image default) works as-is. The username is recorded in exactly one
place, the `User` line of your workstation's `agentbox.conf` (below).

```
sudo apt update && sudo apt install -y git   # just to clone; scripts handle the rest
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

The server prompt is prefixed with the short hostname in magenta, so an ssh
or mosh session into one of several boxes is obviously not your workstation.
That comes from `shell/aliases.server`, linked to `~/.bash_aliases.profile`,
which `aliases.common` sources *after* setting the shared PS1 — so a profile
can override the prompt. `~/.bash_aliases.local` is still yours alone: the
repo never writes it, and it is sourced last so it wins over both.

`bootstrap.sh server` warns to stderr if `~/.bashrc` is missing or doesn't
source `~/.bash_aliases` — this repo only owns `~/.bash_aliases` itself, so
if the user was created without `/etc/skel` (common with cloud-init),
nothing else will source it and the prompt and aliases will silently never
load. Follow the warning's instructions if you see it.

### Workstation side

The `desktop` profile does not install these — reaching the box needs two
tools on the machine you sit at, because both are two-ended:

```
curl -fsSL https://tailscale.com/install.sh | sh   # same installer server-packages.sh uses
sudo tailscale up                                  # join the SAME tailnet as the box
sudo apt install -y mosh                           # server-packages.sh only puts mosh on the box
```

Tailscale is a peer-to-peer mesh, so there is no gateway to route through:
a device that is not on the tailnet cannot reach one that is. Authenticate
with the same identity you used on the box — join under a different login and
the two will never see each other, and `tailscale status` will list only one
machine.

`mosh` matters here for the reason `server-packages.sh` installs it there: it
survives a laptop lid close where plain ssh drops. It has to be on both ends.

Then edit `~/.ssh/config.d/agentbox.conf` — your own copy, not the repo's
template — and replace its three `CHANGEME` placeholders:

- **`User`** — the login the instance was provisioned with.
- **`IdentityFile`** — the key that gets you in, usually the EC2 keypair the
  instance was launched with. **Delete the line** if your default key already
  works; leaving `CHANGEME` there makes ssh warn about an unreadable identity
  file on every connection. This is not the same thing as `ForwardAgent`:
  `IdentityFile` logs you in to the box, the forwarded agent is what lets git
  *on* the box push to GitHub as you.
- **`HostName`** — one of these three, in increasing order of fuss:

| `HostName` value | How to get it | Note |
|---|---|---|
| `agentbox` | the short name, i.e. `hostname -s` on the box | Tailscale puts the tailnet in your DNS search domain, so the bare name normally resolves |
| `100.64.0.2` | column 1 of `tailscale status` | no DNS dependency; changes if you recreate the instance |
| `agentbox.tail1a2b3c.ts.net` | `tailscale status --json \| jq -r '.Self.DNSName' \| sed 's/\.$//'` | the real MagicDNS name |

`server-tailscale.sh` prints the third of those for you at the end of its run.
Note that plain `tailscale status` does **not** show the tailnet suffix — only
the short name and the 100.x IP — so there is nothing in that table to paste
into the `agentbox.CHANGEME.ts.net` form.

Add this as the **first** line of `~/.ssh/config`:

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

## Upgrading an existing machine

`docs/migration-notes.md` lists the pulls that need manual steps. A pull that
moves a symlink target can leave `~/.profile` dangling, which fails silently
until your next login — check there before pulling on a machine that was
configured from an older revision of this repo.

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

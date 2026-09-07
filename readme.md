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

**Set the OS hostname before you run it.** Tailscale registers the machine
under `hostname -s`, which on a fresh EC2 instance is the metadata-derived
`ip-172-31-95-119`. That becomes the machine's name on the tailnet and its
MagicDNS name, and it is also what `\h` shows in the server prompt — so a box
left at the default is both unfindable by a name you would guess and
indistinguishable from any other in the prompt. Naming is per-machine, so the
script deliberately does not invent one:

```
sudo hostnamectl set-hostname NAME
sudo sed -i 's/^127\.0\.1\.1.*/127.0.1.1\tNAME/' /etc/hosts
echo 'preserve_hostname: true' | sudo tee /etc/cloud/cloud.cfg.d/99-preserve-hostname.cfg
```

The second line matters because Debian cloud images map `127.0.1.1` to the old
name, and leaving it stale makes `sudo` warn `unable to resolve host` on every
invocation. The third matters because cloud-init's `update_hostname` module
runs on every boot and will otherwise revert the rename from instance
metadata.

If Tailscale has already registered the box under the old name, re-register it
without re-running the whole script:

```
sudo tailscale set --hostname=NAME
```

Prefer that over renaming in the Tailscale admin console — a client-side
`--hostname` overrides a console rename, so `server-tailscale.sh` would undo it
on its next run.

`agentbox` throughout this readme and in `ssh/agentbox.conf.template` is just
the example name for one such box, not something the server profile requires.

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

That prints a public key to add at https://github.com/settings/keys. Adding it
there — rather than as a per-repo deploy key — gives the box push access to
every repo the account can write, which is the point: one key, no per-repo
plumbing. It also means filesystem read access on the box equals push access
to all of them, so keep the box's reachability narrow (tailnet only, no public
port 22).

Two things make that key actually get used:

- `IdentitiesOnly yes` in the `github.com` block the script writes. Without it
  a forwarded agent's keys are offered first and GitHub takes whichever valid
  one arrives first, so a push can succeed while you are attached and fail
  once you disconnect. Pinning the identity makes both cases behave the same.
- `url."ssh://git@github.com/".insteadOf` in `.gitconfig`, so a repo cloned
  with an https URL still pushes over ssh instead of prompting for a password
  that no agent is there to type.

Run `ssh -T git@github.com` once by hand afterwards, or
`ssh-keyscan github.com >> ~/.ssh/known_hosts` — otherwise the first push
fails with `Host key verification failed`, and non-interactively there is no
prompt to accept the fingerprint.

### herdr

Installed from the client. Nothing is needed on the server for it.

## Upgrading an existing machine

Always re-run bootstrap after pulling, on whichever profile the machine uses:

```
cd ~/wd/dotfiles
git pull
./setup/bootstrap.sh server    # or desktop
exec bash -l
```

`bootstrap.sh` is idempotent and only re-points symlinks — no packages, no
Tailscale — so re-running it costs nothing. It is not optional, though: a pull
that adds a *new* symlink (a new file under `shell/`, `nvim/`, or `bin/`)
leaves that file sitting in the repo with nothing pointing at it. Nothing
dangles and nothing errors; the feature is simply absent until the linking
script runs again.

`exec bash -l` because a running shell keeps the environment and PS1 it was
born with. Note that a reattached tmux session does *not* give you new shells:
open a new window with `prefix c`, or reload one pane with `. ~/.bash_aliases`.

`docs/migration-notes.md` lists the pulls that need manual steps beyond that.
The opposite failure also exists: a pull that *moves* a symlink target can
leave `~/.profile` dangling, which fails silently until your next login —
check there before pulling on a machine configured from an older revision.

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

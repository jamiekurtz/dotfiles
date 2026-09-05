# Migration Notes

Things to do by hand when pulling an update that changes how this repo links
itself. Newest first. If a pull is not listed here, it needs nothing special —
`git pull` and carry on.

---

## 2026-09-05 — desktop/server profile split

Applies to any workstation configured from this repo **before** this change —
`shadowws` (meerkat) and `shadowlt` (p14). Both need the same steps.

### What breaks, and how it fails

Two symlink targets moved:

```
~/.profile       ->  dotfiles/.profile        (now shell/profile.common)
~/.bash_aliases  ->  dotfiles/.bash_aliases   (now shell/aliases.common)
```

The moment you `git pull`, both become dangling. Everything else — sway, foot,
mako, swappy, i3status, nvim, swaycwd, the xdg portals, `.gitconfig`,
`.tmux.conf` — still resolves and is unaffected.

**It fails silently.** Bash tests `[ -f ~/.profile ]`; a dangling symlink fails
that test, so bash sources nothing and prints no error. Your running session
keeps working. The breakage only shows up at your **next login**, as:

- sway not auto-starting on tty1
- no `PATH` additions, no aliases, no prompt

### What to do

Run this after pulling and **before you log out**:

```bash
cd ~/wd/dotfiles
git pull
./setup/bootstrap.sh desktop
. ~/.profile
```

`bootstrap.sh desktop` re-points both dangling links and creates the new ones.
It matches on hostname, so `shadowws` and `shadowlt` each get their own sway
config as before.

Two side effects to expect:

- **It restarts the xdg portals** (`pkill -f xdg-desktop-portal`). This fires
  only when you are in a live sway session on your real login home, which is
  what you want on a workstation — but it will kill an in-progress Slack or
  Zoom screen share. Don't run it mid-meeting.
- **It prints a NOTE** asking you to add `Include config.d/*` as the first line
  of `~/.ssh/config`. That wires up `~/.ssh/config.d/agentbox.conf`, which is a
  **copy** of `ssh/agentbox.conf.template`, not a symlink — edit it freely, it
  will never dirty the repo. Only needed once you have an EC2 box to reach.

No backups are needed. On a machine configured from this repo, the files being
relinked are already symlinks into it, so `ln -sfn` just re-points them.

### Packages

You do **not** need to re-run the package scripts. Only two things are new:

```bash
sudo apt install -y gh
go install github.com/jesseduffield/lazydocker@latest
```

The second fixes the `ld` alias, which had been pointing at a binary nothing
ever installed.

Nothing was dropped from the install set. DBeaver is simply no longer *managed*
by the scripts — it stays installed on machines that already have it. Remove it
by hand with `sudo apt remove dbeaver-ce` if you want it gone.

### Behaviour changes worth knowing

- `clip` is now a script (`~/.local/bin/clip`), not an alias. It uses `wl-copy`
  on a Wayland session and OSC 52 over SSH. The old `alias clip="xclip ..."`
  never worked on these machines — they run Wayland, and xclip talks to X.
- `rng` runs the packaged `ranger` instead of fetching it through pipx.
- tmux now sets `set-clipboard on`. Copy-mode yanks reach the system clipboard
  via foot's OSC 52 support, which they did not before. This is the one change
  you are most likely to actually notice.
- `PATH` entries are now skipped when the directory does not exist, which the
  old comment claimed but the code never did.

### Verifying it worked

```bash
sway -C -c ~/.config/sway/config          # before logging out
readlink -f ~/.profile ~/.bash_aliases    # both must resolve
pwd | clip                                # then paste somewhere
```

Then log out and back in on tty1 and confirm sway still auto-starts.

### If something goes wrong

`touch ~/.no-sway` gets you a plain shell on tty1 to debug from; remove the file
to restore auto-launch. The pre-migration state is `git checkout 9e7abbb` plus
re-running the old `setup/new-sway-links.sh` from that commit.

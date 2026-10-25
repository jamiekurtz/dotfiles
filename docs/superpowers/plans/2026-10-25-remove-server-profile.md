# Plan: remove the server profile, agentbox and Tailscale

Status: **proposed, not started.** Nothing below has been done yet.

The headless EC2 "agent box" experiment didn't work out. This removes the
`server` profile and everything that only existed to support it.

## Recommended scope

Remove the `server` profile and leave the rest of the profile setup alone.
`bootstrap.sh desktop`, `profile.common`/`profile.desktop` and
`~/.dotfiles-profile` all stay. That means the workstations need no
relinking, and a later pull won't break anything. Merging everything into a
single bootstrap with no profile argument is possible, but it's a separate
change with its own migration risk, so leave it out.

## 1. Delete these files

| File | Why |
|---|---|
| `setup/server-packages.sh`, `setup/server-links.sh`, `setup/server-ssh.sh`, `setup/server-tailscale.sh` | Used only by the server profile |
| `shell/profile.server`, `shell/aliases.server` | Same |
| `ssh/agentbox.conf.template` (and the empty `ssh/` folder) | Workstation-side ssh entry for agentbox |
| `setup/test-in-docker.sh` | It only tests the server profile; the desktop links are already covered by `tests/test_links.sh` |
| `docs/superpowers/specs/2026-09-05-headless-server-profile-design.md`, `docs/superpowers/plans/2026-09-05-headless-server-profile.md` | Design notes for a dropped experiment; git history keeps them |

## 2. Edit these files

- **`setup/bootstrap.sh`**: accept only `desktop` (in the usage text and the
  `case`), and drop the "EC2 agent box" line and the
  `# or server-packages.sh` hint.
- **`setup/desktop-links.sh`**:
  - Remove the agentbox copy and the `Include config.d/*` notice.
  - Remove the `~/.ssh/config.d` mkdir and chmods.
  - Remove the step that clears `~/.bash_aliases.profile`.
- **`shell/aliases.common`**: drop the code that loads
  `~/.bash_aliases.profile`. Only the server profile ever filled it.
- **`shell/profile.common`**: change the header comment to say desktop only.
- **`setup/common-packages.sh`**: change "both the desktop and server
  profiles" in the header comment, and the "on the box" wording in the
  LazyVim clone comment.
- **`tests/test_links.sh`**:
  - Rewrite the server section around `bootstrap.sh desktop`, keeping the
    idempotence and `~/.profile` checks.
  - Delete the agentbox copy and no-clobber tests, and the test that
    switching profiles clears the aliases file.
  - Add a check that `bootstrap.sh server` now fails.
- **`tests/test_shell_profiles.sh`**: delete the `profile.server` and
  `aliases.server` blocks. The check that PS1 is set before the aliases file
  loads goes too, since that file is gone. The `SSH_TTY` check stays.
- **`readme.md`**:
  - Replace the two-profile table with a desktop-only intro, and delete the
    whole "Server" section (including the herdr subsection).
  - In "Upgrading", drop `server` and the "no Tailscale" aside.
  - In "Tests", drop the `test-in-docker.sh` line and its paragraph.
  - In "Layout", drop the `ssh/` row and change "profile.desktop/server".
  - Move the short `pwd | clip` explanation into the general docs instead of
    deleting it.
- **`docs/desktop-notes.md`**: drop "None of this applies to the server
  profile."
- **`docs/migration-notes.md`**: add a new entry at the top, "server profile
  removed". It says workstations need nothing beyond `bootstrap.sh desktop`,
  and that the leftover `~/.ssh/config.d/agentbox.conf` and the
  `Include config.d/*` line in `~/.ssh/config` can be deleted by hand. The
  old 2026-09-05 entry stays as history.

## 3. Keep these, but reword comments that mention the server

These came in with the experiment but are useful on their own: ssh-ing
anywhere from foot, and the tmux clipboard on the workstations.

- `bin/clip`: falls back to the terminal's clipboard escape code (OSC 52)
  when there's no Wayland session.
- `.tmux.conf`: `set-clipboard on` and passthrough. Change "headless server"
  to "a remote host over ssh".
- `nvim/init.lua`: the OSC 52 provider when `SSH_TTY` is set. Drop the
  "remote server" wording.
- `.gitconfig` `insteadOf` rewrite: see open decisions.

## 4. Check it works

```
./setup/verify.sh
bash tests/run.sh
grep -rniI -E 'agentbox|tailscale|server|EC2|mosh|headless' --exclude-dir=.git .
```

The grep should only match the old migration note and harmless uses like
`tmux kill-server`.

## 5. Outside the repo (manual)

- On each workstation: `rm ~/.ssh/config.d/agentbox.conf` and remove
  `Include config.d/*` if nothing else uses it.
- Uninstall Tailscale and mosh if you installed them on the workstations.
- Terminate the EC2 instance, remove the machine from the tailnet, and revoke
  the `id_ed25519_agentbox` key at https://github.com/settings/keys. That key
  has push access to every repo the account can write, so revoking it is the
  most important cleanup step.

## Open decisions

1. **`.gitconfig` `url."ssh://git@github.com/".insteadOf https://github.com/`**:
   added for the box, but it also changes how the workstations push.
   Recommendation: keep it and reword the comment.
2. **Merge into a single bootstrap with no profile argument**: recommendation
   is to skip it here, as above.

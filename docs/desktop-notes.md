# Desktop Follow-Up Notes

Things that need doing by hand on a sway workstation after
`setup/desktop-packages.sh`. None of this applies to the server profile.

## Fixing SSO on AWS Client VPN

The following is needed to get AWS Client VPN working with SSO.

```
# 1. Confirm current state is genuinely stable first
cat /etc/resolv.conf
ping -c 2 google.com

# 2. Tell NetworkManager to hand DNS to resolved, before resolved exists
sudo nano /etc/NetworkManager/NetworkManager.conf

# 3. NOW install and enable resolved
sudo apt install systemd-resolved
sudo systemctl restart NetworkManager
sudo systemctl --now enable systemd-resolved

# 4. Check immediately, don't assume
cat /etc/resolv.conf
ping -c 2 google.com
```

If that breaks DNS:

```
sudo systemctl disable --now systemd-resolved
sudo rm -f /etc/resolv.conf
sudo systemctl restart NetworkManager
```

## Laptop Power Management

For power management on a laptop:

```
sudo apt install power-profiles-daemon
powerprofilesctl list
powerprofilesctl set power-saver  # or balanced or performance
```

## Slack screen sharing

The desktop profile links `applications/slack.desktop` over the system
launcher at `~/.local/share/applications/slack.desktop`, so wofi starts Slack
with the PipeWire capturer it needs for screen sharing under sway:

```
Exec=/usr/bin/slack --ozone-platform=x11 --enable-features=WebRTCPipeWireCapturer %U
```

`--ozone-platform=x11` (XWayland) is temporary, added 2026-10-26 to test
whether Slack triggers the sway crash below. It makes Slack blurry at
fractional scales; remove it once the test is over.

## External monitor on the P14 (meetings)

Plug it in and the external display becomes the `11: meeting` workspace
(`$mod+F2`); workspaces 1-10 stay on the laptop panel. `$mod+Shift+F2` sends a
window there. `$mod+o` focuses the other display and `$mod+Shift+o` moves the
current workspace to it; both toggle, so the same keys bring things back. No per-monitor setup: `sway/config.d/p14.conf` binds the meeting
workspace to every connector name the P14 can expose. The status bar only
shows on the panel.

If the external display instead mirrors the panel, the two outputs are
overlapping, not mirroring. Check with:

```
swaymsg -t get_outputs | grep -E '"name"|"x"|"y"'
```

Both at `x: 1920` means the `output * position` wildcard clobbered the panel.
`output *` matches every output, including eDP-1, and sway merges a wildcard
into every output config defined before it, so the panel's `position 0,0` has
to come after the wildcard in the config. Same for `scale`: the wildcard
sets `scale 2` for 4K meeting displays, and the panel's `scale 1` follows it. Workspaces 1-10 are pinned to eDP-1 so a
reload or re-plug can't drag one onto the external display. If one ends up
there anyway, move it back with `$mod+Shift+o` from that display, or
`swaymsg 'move workspace to output eDP-1'`.


## Zoom install and configuration

First download the latest DEB from the Zoom Workplace download center.

Then: 
```
sudo apt install ~/Downloads/zoom_amd64.deb
sudo apt install libxcb-cursor0
cp /usr/share/applications/Zoom.desktop ~/.local/share/applications/Zoom.desktop
vim ~/.local/share/applications/Zoom.desktop

```

Update the Exec line with: `Exec=env WAYLAND_DISPLAY=wayland-1 DISPLAY=:0 QT_QPA_PLATFORM=wayland /usr/bin/zoom %U`

Then:
```
update-desktop-database ~/.local/share/applications
```





## Debugging sway crashes

sway's stdout/stderr go to `~/.local/state/sway/sway.log` (set up in
`shell/profile.desktop`). Each tty1 login rotates the previous session's log
to `sway.log.old`, so after a crash and re-login, look there.

For stack traces, `setup/desktop-packages.sh` installs the systemd core dump
handler. On an older install, add it by hand:

```
sudo apt install systemd-coredump
cat /proc/sys/kernel/core_pattern   # should start with |/usr/lib/systemd/systemd-coredump
```

After a crash:

```
tail -50 ~/.local/state/sway/sway.log.old
coredumpctl list sway
coredumpctl info sway
```

Debug symbols make the trace readable: `sudo apt install debian-goodies`, then
`find-dbgsym-packages $(which sway)` (needs the Debian debug repo enabled).

### 2026-10-23 crash on shadowws (meerkat)

sway 1.10.1 / wlroots 0.18.2 aborted at 16:19:59 with an assertion failure,
seen only in the tty1 console buffer (`sudo cat /dev/vcs1`):

```
...e->width && box->y + box->height <= options->texture->height' failed.
Aborted
```

This is the check that a texture's source box lies within the texture,
probably in wlroots' render pass. No kernel segfault, GPU/DRM error or OOM
in the journal. Suspected trigger is the fractional scaling added on
2026-10-21 in `sway/config.d/meerkat.conf` (secondary `scale 1.6` with
`transform 270`, primary `scale 1.5`). Not confirmed: no core dump or full
log existed at the time. If it recurs, grab the full assertion from the log
and the `coredumpctl info` trace; then try integer or matching scales, check
for a wlroots newer than 0.18.2, or report upstream.

### 2026-10-26 recurrence

Same abort at 08:45:18, now with both outputs at `scale 1.75` (secondary still
`transform 270`), so changing the fractional values did not help. Full text,
recovered from the core dump (`coredumpctl dump <pid> -o sway.core`, then
`strings sway.core | grep Assertion`):

```
sway: render/pass.c:23: wlr_render_pass_add_texture: Assertion `box->x >= 0 && box->y >= 0 && box->x + box->width <= options->texture->width && box->y + box->height <= options->texture->height' failed.
```

There was no `sway.log`: `~/.no-sway` exists, so sway was started by hand
from the tty1 shell and logged to tty1, not through `shell/profile.desktop`.

Native-Wayland Chromium clients running at the time: Slack, Chrome,
1Password. Experiment: Slack moved to XWayland via `applications/slack.desktop`
(see "Slack screen sharing"). No more crashes points at Slack; a crash
anyway rules it out.

Result: sway aborted again at 10:32:01 with the same assertion while Slack
was on XWayland (confirmed with
`swaymsg -t get_tree | grep -B5 '"shell": "xwayland"'`), so Slack is ruled
out. Next experiment: both outputs at integer `scale 2` (primary offset 800),
Slack still on XWayland. No crash points at fractional scaling; a crash
moves suspicion to Chrome, which would go to XWayland next.

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

After installing Slack (e.g. using their official Debian package), you need to update
the associated shortcut as follows:

```
cp /usr/share/applications/slack.desktop ~/.local/share/applications
vim ~/.local/share/applications/slack.desktop
```

Insert the following pipewire argument into the Exec line to make it look like:

```
Exec=/usr/bin/slack --enable-features=WebRTCPipeWireCapturer %U
```



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





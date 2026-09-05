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



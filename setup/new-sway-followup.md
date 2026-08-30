
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

# Debian 13 Wi-Fi NetworkManager Fix

This guide outlines the steps to resolve the `"Scanning not allowed while unavailable"` error in Debian 13. This issue typically occurs because the Debian installer hardcodes the primary Wi-Fi interface into the legacy `ifupdown` configuration, preventing NetworkManager from managing the wireless card.

Requires that network-manager has been installed.

## Step 1: Disable Legacy Wi-Fi Configuration

You must comment out the installer-created wireless configuration to release the interface to NetworkManager.

1. Open the legacy network interfaces configuration file:
   ```bash
   sudo nano /etc/network/interfaces
   ```

2. Locate the section for your Wi-Fi interface (e.g., `wlp2s0`) and comment out the lines by adding a `#` at the beginning of each:
   ```text
   # The primary network interface
   #allow-hotplug wlp2s0
   #iface wlp2s0 inet dhcp
   #        wpa-ssid your_installer_ssid
   #        wpa-psk  your_installer_password
   ```

3. Save the file (`Ctrl+O`, `Enter`) and exit (`Ctrl+X`).

## Step 2: Ensure NetworkManager is Set to Managed

Verify that NetworkManager is permitted to manage interfaces defined in the legacy configuration.

1. Open the NetworkManager configuration file:
   ```bash
   sudo nano /etc/NetworkManager/NetworkManager.conf
   ```

2. Ensure the `[ifupdown]` block has `managed` set to `true`:
   ```ini
   [ifupdown]
   managed=true
   ```

3. Save and exit the file.

## Step 3: Clear the Device State & Reset Network Services

Force-kill lingering legacy processes and reset the interface link so NetworkManager can cleanly claim ownership.

```bash
# 1. Force the physical interface down to break any existing connection hooks
sudo ip link set wlp2s0 down

# 2. Flush any IP addresses assigned by the legacy service
sudo ip addr flush dev wlp2s0

# 3. Kill lingering background DHCP and WPA processes tied to the installer connection
sudo pkill dhclient
sudo pkill wpa_supplicant

# 4. Restart NetworkManager to discover and claim the free Wi-Fi card
sudo systemctl restart NetworkManager
```

## Step 4: Verify and Connect

Your interface should now transition from `unavailable` to `disconnected` (ready to connect).

1. **Scan for Wi-Fi Networks:**
   ```bash
   nmcli device wifi rescan && sleep 5 && nmcli device wifi list
   ```

2. **Manage Connections (Interactive UI):**
   ```bash
   nmtui
   ```

## Post-Install: Enable US Regulatory Domain for 5GHz/6GHz Wi-Fi

By default, a fresh Debian install may default to a generic global regulatory domain (`country 00`). This can block or severely restrict 5GHz and 6GHz Wi-Fi frequencies due to conservative local transmission laws. 

Follow these steps to permanently lock your system to the US regulatory domain to ensure full 5GHz functionality.

### 1. Install Required Wireless Utilities
Ensure you have the proper tools installed to view and modify wireless settings:
```bash
sudo apt update
sudo apt install iw wireless-regdb crda
```

### 2. Set the US Country Code Permanently
To make the regulatory domain stick across reboots, you must configure the kernel's configuration files:

1. Open or create the configuration file in your preferred text editor:
   ```bash
   sudo nano /etc/default/crda
   ```
2. Find the `REGDOMAIN=` line and modify it to target the US:
   ```text
   REGDOMAIN=US
   ```
3. Save and close the file (`Ctrl+O`, `Enter`, then `Ctrl+X` in Nano).

### 3. Apply and Verify the Changes
Restart your networking stack or simply reboot your system to apply the new regulatory rules:
```bash
sudo reboot
```

After logging back in, run the following verification checks:

* **Check Country Constraints:**
  ```bash
  sudo iw reg get
  ```
  *Verification:* Look for a section starting with `phy#0` or your active adapter that explicitly says `country US`. You should see frequency bands listed up to `5855` (and `7125` if your card supports Wi-Fi 6E/7).

* **Scan for 5GHz Access Points:**
  Identify your wireless interface name using `ip a` (e.g., `wlp2s0`) and run a targeted frequency scan:
  ```bash
  sudo iw dev wlp2s0 scan | grep -E "SSID|freq:"
  ```
  *Verification:* Ensure you are seeing live networks broadcasting in the `5xxx.0` MHz ranges.


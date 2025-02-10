# openwrt-pbr-iran-rules 🇮🇷

This repository provides a comprehensive set of rules to route Iranian IP traffic on OpenWRT using **luci-app-pbr**. These rules enable you to segregate domestic traffic (from Iran) from VPN or other routes, offering more precise control over your internet traffic.

## 🚀 Installation Guide

### 1. **Install Required Packages**:
   - On your OpenWRT router, install the following packages:
     - `luci-app-pbr`
     - `pbr`

### 2. **Download the Custom Script**:
   - SSH into your router and download the appropriate script to the path `/usr/share/pbr/`:
   
   - **Online Version**:
     If you want to fetch the list of Iranian IPs dynamically from an online source, run the following command:
     ```bash
     wget -P /usr/share/pbr/ https://raw.githubusercontent.com/WhoisGray/openwrt-pbr-iran-rules/main/pbr.user.iran.sh
     ```

   - **Offline Version**:
     If you prefer using an offline version, which includes predefined Iranian IP ranges, use the following command instead:
     ```bash
     wget -P /usr/share/pbr/ https://raw.githubusercontent.com/WhoisGray/openwrt-pbr-iran-rules/main/pbr.user.iran.offline.sh
     ```

   - **Important**: If you encounter the error `Change output directory: No such file or directory`, create the necessary directory:
     ```bash
     mkdir -p /usr/share/pbr/
     ```

### 3. **Configure Policy Routing**:
   - Access your router’s **Web Admin (LuCI)** interface.
   - Navigate to **Services > Policy Routing**.
   - Add a new **Custom User File** and specify the following path:
     ```
     /usr/share/pbr/pbr.user.iran.sh
     ```
   - If you used the offline version, the path would be `/usr/share/pbr/pbr.user.iran.offline.sh`.
   - Enable the rule and click **Done** to save the configuration.

### 4. **Save and Reboot**:
   - After adding and enabling the custom script, save the changes and reboot your router for the configuration to take effect.

## ⚙️ Configuration

This script fetches a list of Iranian IP addresses and creates policy routing rules to handle the segregation of domestic traffic. The list of IPs is dynamically retrieved from a reliable source and regularly updated to ensure accuracy.

### 🌍 **Iranian IP Source**

The Iranian IP list is sourced from [MrAriaNet/Get-IP-Iran](https://github.com/MrAriaNet/Get-IP-Iran).

### 🌐 **Offline Version**

If you prefer to use an offline version or if the online repository becomes unavailable, you can download the offline script, which includes the IP ranges directly within the script itself.

---

## 🔧 Troubleshooting

If you experience issues or have suggestions for improvements, feel free to open an issue or submit a pull request on the [GitHub repository](https://github.com/WhoisGray/openwrt-pbr-iran-rules).

## 📜 License

This project is licensed under the MIT License.

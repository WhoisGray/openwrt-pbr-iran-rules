# openwrt-pbr-iran-rules 🇮🇷

[English](./README.md) | [فارسی](./README.fa.md)

This repository provides a comprehensive set of rules to route Iranian IP traffic on OpenWRT using **luci-app-pbr**. These rules enable you to segregate domestic traffic (from Iran) from VPN or other routes, offering more precise control over your internet traffic.

## 🚀 Installation Guide

### 1. **Install Required Packages**:
   - On your OpenWRT router, run:
     ```sh
     opkg update
     opkg install luci-app-pbr pbr uclient-fetch
     ```
   - `uclient-fetch` is usually already installed; the script can also use `curl` or `wget`.

### 2. **Choose and install a script**:
   - **Online (recommended for automatically refreshed lists):**
     ```bash
     mkdir -p /usr/share/pbr
     uclient-fetch -O /usr/share/pbr/pbr.user.iran.sh \
       https://raw.githubusercontent.com/WhoisGray/openwrt-pbr-iran-rules/main/pbr.user.iran.sh
     chmod 755 /usr/share/pbr/pbr.user.iran.sh
     ```

   - **Offline (no internet access required when PBR runs):**
     ```bash
     uclient-fetch -O /usr/share/pbr/pbr.user.iran.offline.sh \
       https://raw.githubusercontent.com/WhoisGray/openwrt-pbr-iran-rules/main/pbr.user.iran.offline.sh
     chmod 755 /usr/share/pbr/pbr.user.iran.offline.sh
     ```
     Downloading the script initially requires internet access; after installation, the embedded list works independently.

### 3. **Configure Policy Routing**:
   - Access your router’s **Web Admin (LuCI)** interface.
   - Navigate to **Services > Policy Routing**.
   - Add the downloaded script as the **Custom User File**, for example:
     ```
     /usr/share/pbr/pbr.user.iran.sh
     ```
   - Enable the rule and click **Done** to save the configuration.

### 4. **Apply the configuration**:
   - Save the configuration, then restart Policy Routing from LuCI or run `/etc/init.d/pbr restart`.
   - The online list refreshes whenever this script runs. To refresh it automatically every day without restarting PBR, add a cron job:
     ```sh
     grep -qF '/usr/share/pbr/pbr.user.iran.sh' /etc/crontabs/root || \
       echo '15 4 * * * /usr/share/pbr/pbr.user.iran.sh >/tmp/pbr-iran-update.log 2>&1' >> /etc/crontabs/root
     /etc/init.d/cron restart
     ```
     This runs the online script daily at 04:15. For the offline script, a cron job is unnecessary.

## ⚙️ Configuration

Both scripts validate IPv4 prefixes, remove duplicates, and add the resulting ranges to the PBR nftables set (or legacy ipset).

- **Online script:** fetches the lists whenever Policy Routing runs. It applies only prefixes present in both a primary-source list and a community-source list. A failed or incomplete source is ignored; if the remaining sources cannot agree on a usable list, it reports an error and leaves the existing rules unchanged.
- **Offline script:** contains a complete deduplicated snapshot in the script itself and does not make network requests. Its embedded snapshot was assembled from the sources below on 2026-11-12. To refresh it, download a newer offline script from this repository.
- **Safety checks:** online updates require agreement between at least one primary source (RIPE/IPdeny) and one community source. RIPE is a regional Internet registry; IPdeny is an independent public list, not an official registry. Invalid, non-canonical, private, reserved, or unexpectedly large lists are rejected; an update is skipped if the source groups do not agree.
- The lists are treated only as data; downloaded content is never executed as shell code. These checks reduce risk from a single compromised list source, but cannot protect against simultaneous compromise of multiple independent sources or tampering with the script/repository itself. Review and manually install script updates.

### 🌍 **Online sources and offline snapshot references**

- [RIPE Stat country resource list](https://stat.ripe.net/data/country-resource-list/data.json?resource=IR&v4_format=prefix) — official regional Internet registry data.
- [IPdeny country zone](https://www.ipdeny.com/ipblocks/data/countries/ir.zone) — public country IP list.
- [MrAriaNet/Get-IP-Iran](https://github.com/MrAriaNet/Get-IP-Iran)
- [farshidmousavii/iran-ip-ranges](https://github.com/farshidmousavii/iran-ip-ranges)

---

## 🔧 Troubleshooting

If you experience issues or have suggestions for improvements, feel free to open an issue or submit a pull request on the [GitHub repository](https://github.com/WhoisGray/openwrt-pbr-iran-rules).

## 📜 License

This project is licensed under the MIT License.

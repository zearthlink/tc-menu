# Raspberry Pi 5 — Inline L2 Bridge + tc-menu (v2.4)

End-to-end setup for an inline L2 bridge using `eth1`↔`eth2` (USB NICs) with management on `eth0`, and the **tc-menu v2.4** controller for `tc/netem`.

---

## 1) Update OS & firmware (stable track)

**Update & reboot:**
```bash
sudo apt update
sudo apt full-upgrade -y
sudo rpi-eeprom-update -a
sudo reboot
```

**Install tools (after reboot):**
```bash
sudo apt install -y network-manager iproute2 ethtool bridge-utils iperf3
```

---

## 2) Pin stable names for the two USB NICs

**Identify MACs:**
```bash
ip -br link
```

**Create udev rule (replace MACs):**
```bash
sudo nano /etc/udev/rules.d/70-persistent-net.rules
```

**Contents:**
```text
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="aa:bb:cc:dd:ee:01", NAME="eth1"
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="aa:bb:cc:dd:ee:02", NAME="eth2"

# Replace "aa:bb:cc:dd:ee:01" "aa:bb:cc:dd:ee:02" with your own MACs
```

**Apply (simple path = reboot):**
```bash
sudo udevadm control --reload
sudo reboot
```

---

## 3) Configure management on `eth0` (example: `192.168.0.162/24`)

NetworkManager is the default.

**Find the `eth0` connection name:**
```bash
nmcli -f NAME,DEVICE,TYPE con show
```

**3.1 Modify existing profile (replace the name):**
```bash
sudo nmcli con mod <YOUR-ETH0-CONNECTION-NAME> \
  ipv4.addresses 192.168.0.162/24 \
  ipv4.gateway 192.168.0.1 \
  ipv4.dns "1.1.1.1 8.8.8.8" \
  ipv4.method manual \
  ipv6.method ignore

sudo nmcli dev reapply eth0 || ( \
  sudo nmcli con down <YOUR-ETH0-CONNECTION-NAME>; \
  sudo nmcli con up   <YOUR-ETH0-CONNECTION-NAME> )
```

**3.2 Create a fresh `eth0` profile (if none exists):**
```bash
sudo nmcli con add type ethernet ifname eth0 con-name eth0 \
  ipv4.addresses 192.168.0.162/24 ipv4.gateway 192.168.0.1 \
  ipv4.dns "1.1.1.1 8.8.8.8" ipv4.method manual ipv6.method ignore
sudo nmcli con up eth0

# Substitute the placeholder IP address with the required host address and specify the correct default gateway for the network.
```
---

## 4) Build the inline L2 bridge (no IP on `br0`)

**4.1 Create `br0` and enslave `eth1` & `eth2`:**
```bash
# Create empty bridge (no IP), STP off
sudo nmcli con add type bridge ifname br0 con-name br0
sudo nmcli con mod br0 ipv4.method disabled ipv6.method ignore bridge.stp no

# Add the two USB NICs as bridge ports
sudo nmcli con add type ethernet ifname eth1 master br0 con-name br0-eth1
sudo nmcli con add type ethernet ifname eth2 master br0 con-name br0-eth2

# Bring up
sudo nmcli con up br0
sudo nmcli con up br0-eth1
sudo nmcli con up br0-eth2
```

**4.2 (Optional) keep Wi-Fi off for a single mgmt path**
```bash
nmcli radio wifi off
```

**4.3 Verify**
```bash
nmcli d
bridge link
ip -br addr show br0   # should show NO IP
```

**4.4 Keep datapath pure L2 (no bridge netfilter)**
```bash
lsmod | grep br_netfilter || echo "br_netfilter not loaded (good)"
[ -d /proc/sys/net/bridge ] && ls /proc/sys/net/bridge || echo "no /proc/sys/net/bridge (good)"
```

**4.5 (Optional) disable large offloads during testing**
```bash
sudo ethtool -K eth1 gro off gso off tso off lro off
sudo ethtool -K eth2 gro off gso off tso off lro off
# Restore with 'on' when finished.
# Note: deprecated once the script menu includes an offload toggle.
```

---

## 5) Install the menu-driven `tc` script (logging + Show Status)

Replaces manual/persistent tc steps.

- Direction prompts: LAN→WAN = apply on `eth2` egress; WAN→LAN = apply on `eth1` egress; BOTH applies both.
- Optional global rate-cap wrapper: root **HTB** + class `1:1` + child **NETEM** when `RATE_CAP` is set.

**5.1 Install**
```bash
sudo nano /usr/local/sbin/tc-menu.sh
# paste the tc-menu v2.4 script
sudo chmod +x /usr/local/sbin/tc-menu.sh
sudo bash -n /usr/local/sbin/tc-menu.sh   # syntax check
```

---

## 6) (Optional) log rotation
```bash
sudo tee /etc/logrotate.d/tc-menu >/dev/null <<'EOF'
/var/log/tc-menu.log {
  rotate 7
  daily
  missingok
  notifempty
  compress
  delaycompress
  create 0644 root root
}
EOF
```

---

## 7) Run
```bash
sudo /usr/local/sbin/tc-menu.sh
```

**7.1 Live counters (new terminal):**
```bash
watch -n1 'tc -s qdisc show dev eth1; echo; tc -s qdisc show dev eth2'
```
Generate traffic across the bridge (`ping`, `iperf3`) to observe counters.

**7.2 Persistence**
- Shaping remains active until cleared, reset, or rebooted (no auto-apply at boot unless a service is added).

**7.3 Optional environment overrides (set at launch)**
```bash
# Interface roles
sudo LAN_IF=eth1 WAN_IF=eth2 /usr/local/sbin/tc-menu.sh

# Global HTB wrapper for all NETEM profiles (not #6)
sudo RATE_CAP=5mbit RATE_BURST=64kb /usr/local/sbin/tc-menu.sh

# Enable ingress menu
sudo USE_IFB=1 /usr/local/sbin/tc-menu.sh

# Start in dry-run
sudo DRY_RUN=1 /usr/local/sbin/tc-menu.sh

# Override DSCP defaults (decimal)
sudo TEAMS_AUDIO_DSCP=46 TEAMS_VIDEO_DSCP=34 /usr/local/sbin/tc-menu.sh
```

---

## 8) Logging
- Actions and status snapshots → `/var/log/tc-menu.log` (compatible with the logrotate rule).
- Dry-run emissions are prefixed `DRY-RUN:`.

---

## 9) Identify which dongle has link

**9.1 carrier / operstate**
```bash
for i in eth1 eth2; do
  printf "%s  carrier=%s  operstate=%s\n" \
    "$i" \
    "$(cat /sys/class/net/$i/carrier 2>/dev/null)" \
    "$(cat /sys/class/net/$i/operstate 2>/dev/null)"
done
# carrier=1 and operstate=up == has cable
```

**9.2 quick view**
```bash
ip -br link show eth1
ip -br link show eth2
# look for LOWER_UP on the cabled interface
```

**9.3 ethtool (speed + link)**
```bash
for i in eth1 eth2; do
  echo "[$i]"
  ethtool "$i" | egrep 'Speed:|Duplex:|Link detected:'
done
```

**9.4 live watch while plugging**
```bash
ip monitor link
# shows: "ethX: link becomes ready"
```

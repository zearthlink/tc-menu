# Hardware used
_Generated: 2025-08-21T02:24:04+01:00; SAFE=1_

## Host & OS

```
### OS release
PRETTY_NAME="Raspbian GNU/Linux 12 (bookworm)"
NAME="Raspbian GNU/Linux"
VERSION_ID="12"
VERSION="12 (bookworm)"
VERSION_CODENAME=bookworm
ID=raspbian
ID_LIKE=debian
HOME_URL="http://www.raspbian.org/"
SUPPORT_URL="http://www.raspbian.org/RaspbianForums"
BUG_REPORT_URL="http://www.raspbian.org/RaspbianBugs"

### Kernel
Linux raspberrypi 6.12.34+rpt-rpi-v8 #1 SMP PREEMPT Debian 1:6.12.34-1+rpt1~bookworm (2025-06-26) aarch64 GNU/Linux
```


## Firmware / EEPROM

```
2025/05/08 [IPv6-redacted]
Copyright (c) 2012 Broadcom
version 69471177 (release) (embedded)
BOOTLOADER: up to date
   CURRENT: Thu May  8 [IPv6-redacted] PM UTC 2025 (1746713597)
    LATEST: Thu May  8 [IPv6-redacted] PM UTC 2025 (1746713597)
   RELEASE: default (/usr/lib/firmware/raspberrypi/bootloader-2712/default)
            Use raspi-config to change the release.
```


## Board & CPU

```
Architecture:                            aarch64
Byte Order:                              Little Endian
CPU(s):                                  4
On-line CPU(s) list:                     0-3
Vendor ID:                               ARM
Model name:                              Cortex-A76
Model:                                   1
Thread(s) per core:                      1
Core(s) per cluster:                     4
Socket(s):                               -
Cluster(s):                              1
Stepping:                                r4p1
CPU(s) scaling MHz:                      62%
CPU max MHz:                             2400.0000
CPU min MHz:                             1500.0000
BogoMIPS:                                108.00
Flags:                                   fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm lrcpc dcpop asimddp
L1d cache:                               256 KiB (4 instances)
L1i cache:                               256 KiB (4 instances)
L2 cache:                                2 MiB (4 instances)
L3 cache:                                2 MiB (1 instance)
NUMA node(s):                            8
NUMA node0 CPU(s):                       0-3
NUMA node1 CPU(s):                       0-3
NUMA node2 CPU(s):                       0-3
NUMA node3 CPU(s):                       0-3
NUMA node4 CPU(s):                       0-3
NUMA node5 CPU(s):                       0-3
NUMA node6 CPU(s):                       0-3
NUMA node7 CPU(s):                       0-3
Vulnerability Gather data sampling:      Not affected
Vulnerability Indirect target selection: Not affected
Vulnerability Itlb multihit:             Not affected
Vulnerability L1tf:                      Not affected
Vulnerability Mds:                       Not affected
Vulnerability Meltdown:                  Not affected
Vulnerability Mmio stale data:           Not affected
Vulnerability Reg file data sampling:    Not affected
Vulnerability Retbleed:                  Not affected
Vulnerability Spec rstack overflow:      Not affected
Vulnerability Spec store bypass:         Mitigation; Speculative Store Bypass disabled via prctl
Vulnerability Spectre v1:                Mitigation; __user pointer sanitization
Vulnerability Spectre v2:                Mitigation; CSV2, BHB
Vulnerability Srbds:                     Not affected
Vulnerability Tsx async abort:           Not affected

Revision        : d04170
Model           : Raspberry Pi 5 Model B Rev 1.0
```


## Memory

```
               total        used        free      shared  buff/cache   available
Mem:           7.8Gi       395Mi       6.8Gi        22Mi       651Mi       7.4Gi
Swap:          199Mi          0B       199Mi
```


## Storage

```
NAME        HCTL TRAN ROTA   SIZE MODEL SERIAL     MOUNTPOINT
mmcblk0                  0 233.2G       0x3587d028
├─mmcblk0p1              0   512M                  /boot/firmware
└─mmcblk0p2              0 232.7G                  /

Filesystem      Size  Used Avail Use% Mounted on
/dev/mmcblk0p2  230G  5.5G  212G   3% /
/dev/mmcblk0p1  510M  120M  391M  24% /boot/firmware
```


## Network — overview

```
lo               UNKNOWN        127.0.xx.xx/8 ::1/128
eth0             DOWN           192.168.xx.xx/24
eth1             DOWN
eth2             DOWN
wlan0            UP             192.168.xx.xx/24 [IPv6-redacted]/64 fe80::[IPv6-redacted]/64
br0              DOWN

lo               UNKNOWN        [IPv6-redacted]xx:xx:xx <LOOPBACK,UP,LOWER_UP>
eth0             DOWN           [IPv6-redacted]xx:xx:xx <NO-CARRIER,BROADCAST,MULTICAST,UP>
eth1             DOWN           [IPv6-redacted]xx:xx:xx <NO-CARRIER,BROADCAST,MULTICAST,UP>
eth2             DOWN           [IPv6-redacted]xx:xx:xx <NO-CARRIER,BROADCAST,MULTICAST,UP>
wlan0            UP             [IPv6-redacted]xx:xx:xx <BROADCAST,MULTICAST,UP,LOWER_UP>
br0              DOWN           [IPv6-redacted]xx:xx:xx <NO-CARRIER,BROADCAST,MULTICAST,UP>

eth0:ethernet:connected
wlan0:wifi:connected
lo:loopback:connected (externally)
br0:bridge:connected
eth1:ethernet:connected
eth2:ethernet:connected
p2p-dev-wlan0:wifi-p2p:disconnected
```


## Network — eth0 details

```
## ethtool (eth0)
        Speed: Unknown!
        Duplex: Unknown! (255)
        Link detected: no

## driver (eth0)
driver: macb
version: 6.12.34+rpt-rpi-v8
firmware-version:
expansion-rom-version:
bus-info: 1f00100000.ethernet
supports-statistics: yes
supports-test: no
supports-eeprom-access: no
supports-register-dump: yes
supports-priv-flags: no

## udev attributes (eth0)
```


## Network — eth1 details

```
## ethtool (eth1)
        Speed: 10Mb/s
        Duplex: Half
        Link detected: no

## driver (eth1)
driver: r8152
version: v1.12.13
firmware-version: rtl8153a-4 v2 02/07/20
expansion-rom-version:
bus-info: usb-xhci-hcd.1-1
supports-statistics: yes
supports-test: no
supports-eeprom-access: no
supports-register-dump: no
supports-priv-flags: no

## udev attributes (eth1)
```


## Network — eth2 details

```
## ethtool (eth2)
        Speed: 10Mb/s
        Duplex: Half
        Link detected: no

## driver (eth2)
driver: r8152
version: v1.12.13
firmware-version: rtl8153a-4 v2 02/07/20
expansion-rom-version:
bus-info: usb-xhci-hcd.0-1
supports-statistics: yes
supports-test: no
supports-eeprom-access: no
supports-register-dump: no
supports-priv-flags: no

## udev attributes (eth2)
```


## Bridge (br0) topology

```
3: eth1: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 master br0 state disabled priority 32 cost 100
    hairpin off guard off root_block off fastleave off learning on flood on mcast_flood on bcast_flood on mcast_router 1 mcast_to_unicast off neigh_suppress off vlan_tunnel off isolated off locked off
4: eth2: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 master br0 state disabled priority 32 cost 100
    hairpin off guard off root_block off fastleave off learning on flood on mcast_flood on bcast_flood on mcast_router 1 mcast_to_unicast off neigh_suppress off vlan_tunnel off isolated off locked off

port              vlan-id
eth1              1 PVID Egress Untagged
                    state forwarding mcast_router 1
eth2              1 PVID Egress Untagged
                    state forwarding mcast_router 1
```


## USB topology

```
Bus 004 Device 002: ID 0bda:8153 Realtek Semiconductor Corp. RTL8153 Gigabit Ethernet Adapter
Bus 004 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 003 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 002 Device 002: ID 0bda:8153 Realtek Semiconductor Corp. RTL8153 Gigabit Ethernet Adapter
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 002: ID 1532:0084 Razer USA, Ltd RZ01-0321 Gaming Mouse [DeathAdder V2]
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub

/:  Bus 04.Port 1: Dev 1, Class=root_hub, Driver=xhci-hcd/1p, 5000M
    |__ Port 1: Dev 2, If 0, Class=Vendor Specific Class, Driver=r8152, 5000M
/:  Bus 03.Port 1: Dev 1, Class=root_hub, Driver=xhci-hcd/2p, 480M
/:  Bus 02.Port 1: Dev 1, Class=root_hub, Driver=xhci-hcd/1p, 5000M
    |__ Port 1: Dev 2, If 0, Class=Vendor Specific Class, Driver=r8152, 5000M
/:  Bus 01.Port 1: Dev 1, Class=root_hub, Driver=xhci-hcd/2p, 480M
    |__ Port 2: Dev 2, If 0, Class=Human Interface Device, Driver=usbhid, 12M
    |__ Port 2: Dev 2, If 1, Class=Human Interface Device, Driver=usbhid, 12M
    |__ Port 2: Dev 2, If 2, Class=Human Interface Device, Driver=usbhid, 12M
    |__ Port 2: Dev 2, If 3, Class=Human Interface Device, Driver=usbhid, 12M
```


## PCIe (if present)

```
[IPv6-redacted].0 PCI bridge [0604]: Broadcom Inc. and subsidiaries BCM2712 PCIe Bridge [14e4:2712] (rev 21) (prog-if 00 [Normal decode])
        Control: I/O- Mem+ BusMaster+ SpecCycle- MemWINV- VGASnoop- ParErr- Stepping- SERR- FastB2B- DisINTx-
        Status: Cap+ 66MHz- UDF- FastB2B- ParErr- DEVSEL=fast >TAbort- <TAbort- <MAbort- >SERR- <PERR- INTx-
        Latency: 0
        Interrupt: pin A routed to IRQ 38
        Bus: primary=00, secondary=01, subordinate=01, sec-latency=0
        Memory behind bridge: 00000000-005fffff [size=6M] [32-bit]
        Prefetchable memory behind bridge: [disabled] [64-bit]
        Secondary status: 66MHz- FastB2B- ParErr- DEVSEL=fast >TAbort- <TAbort- <MAbort- <SERR- <PERR-
        BridgeCtl: Parity- SERR- NoISA- VGA- VGA16- MAbort- >Reset- FastB2B-
                PriDiscTmr- SecDiscTmr- DiscTmrStat- DiscTmrSERREn-
        Capabilities: <access denied>
        Kernel driver in use: pcieport

[IPv6-redacted].0 Ethernet controller [0200]: Raspberry Pi Ltd RP1 PCIe 2.0 South Bridge [1de4:0001]
        Control: I/O- Mem+ BusMaster+ SpecCycle- MemWINV- VGASnoop- ParErr- Stepping- SERR- FastB2B- DisINTx+
        Status: Cap+ 66MHz- UDF- FastB2B- ParErr- DEVSEL=fast >TAbort- <TAbort- <MAbort- >SERR- <PERR- INTx-
        Latency: 0
        Interrupt: pin A routed to IRQ 38
        Region 0: Memory at 1f00410000 (32-bit, non-prefetchable) [size=16K]
        Region 1: Memory at 1f00000000 (32-bit, non-prefetchable) [virtual] [size=4M]
        Region 2: Memory at 1f00400000 (32-bit, non-prefetchable) [size=64K]
        Capabilities: <access denied>
        Kernel driver in use: rp1

```


## Kernel messages (NICs & USB Ethernet)

```
[    0.000000] Kernel command line: reboot=w coherent_pool=1M 8250.nr_uarts=1 pci=pcie_bus_safe cgroup_disable=memory numa_policy=interleave nvme.max_host_mem_size_mb=0  numa=fake=8 system_heap.max_order=0 smsc95xx.macaddr=[IPv6-redacted]xx:xx:xx vc_mem.mem_base=0x3fc00000 vc_mem.mem_size=0x40000000  console=ttyAMA10,115200 console=tty1 root=PARTUUID=28076b05-02 rootfstype=ext4 fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles cfg80211.ieee80211_regdom=GB
[    0.281018] usbcore: registered new interface driver lan78xx
[    0.281026] usbcore: registered new interface driver smsc95xx
[    0.429662] macb 1f00100000.ethernet eth0: Cadence GEM rev 0x00070109 at 0x1f00100000 irq 106 ([IPv6-redacted]xx:xx:xx)
[    0.930931] usbcore: registered new device driver r8152-cfgselector
[    1.104433] r8152-cfgselector 4-1: reset SuperSpeed USB device number 2 using xhci-hcd
[    1.279381] r8152-cfgselector 2-1: reset SuperSpeed USB device number 2 using xhci-hcd
[    1.327506] r8152 4-1:1.0 eth1: v1.12.13
[    1.452088] r8152 2-1:1.0 eth2: v1.12.13
[    1.452215] usbcore: registered new interface driver r8152
[    1.452664] usbcore: registered new interface driver cdc_ether
[    6.049005] macb 1f00100000.ethernet eth0: PHY [1f00100000.ethernet-ffffffff:01] driver [Broadcom BCM54213PE] (irq=POLL)
[    6.049014] macb 1f00100000.ethernet eth0: configuring for phy/rgmii-id link mode
[ 2198.472412] br0: port 1(eth1) entered blocking state
[ 2198.472483] br0: port 1(eth1) entered disabled state
[ 2198.472506] r8152 4-1:1.0 eth1: entered allmulticast mode
[ 2198.472583] r8152 4-1:1.0 eth1: entered promiscuous mode
[ 2198.531750] br0: port 2(eth2) entered blocking state
[ 2198.531776] br0: port 2(eth2) entered disabled state
[ 2198.531832] r8152 2-1:1.0 eth2: entered allmulticast mode
[ 2198.532140] r8152 2-1:1.0 eth2: entered promiscuous mode
```


## Temperature / throttling

```
temp=56.5'C
throttled=0x0
```


## lshw summary (optional)

```
H/W path   Device          Class          Description
=====================================================
                           system         Raspberry Pi 5 Model B Rev 1.0
/0                         bus            Motherboard
/0/1                       processor      cpu
/0/1/0                     memory         64KiB L1 Cache
/0/2                       processor      cpu
/0/2/0                     memory         64KiB L1 Cache
/0/3                       processor      cpu
/0/3/0                     memory         64KiB L1 Cache
/0/4                       processor      cpu
/0/4/0                     memory         64KiB L1 Cache
/0/5                       processor      l3-cache
/0/6                       memory         7952MiB System memory
/0/0                       bridge         Broadcom Inc. and subsidiaries
/0/0/0                     network        Ethernet controller
/1         usb1            bus            xHCI Host Controller
/1/2       input5          input          Razer Razer DeathAdder V2
/2         usb2            bus            xHCI Host Controller
/2/1                       generic        USB 10/100/1000 LAN
/3         usb3            bus            xHCI Host Controller
/4         usb4            bus            xHCI Host Controller
/4/1                       generic        USB 10/100/1000 LAN
/5         mmc0            bus            MMC Host
/5/544c    /dev/mmcblk0    disk           250GB USD00
/5/544c/1                  volume         512MiB Windows FAT volume
/5/544c/2  /dev/mmcblk0p2  volume         232GiB EXT4 volume
/6         mmc1            bus            MMC Host
/6/1                       generic        SDIO Device
/6/1/1     mm[IPv6-redacted]     network        4345
/6/1/2     mm[IPv6-redacted]     generic        4345
/6/1/3     mm[IPv6-redacted]     communication  4345
/7         card0           multimedia     vc4hdmi0
/8         card1           multimedia     vc4hdmi1
/9         /dev/fb0        display        vc4drmfb
/a         input0          input          pwr_button
/b         input1          input          vc4-hdmi-0
/c         input2          input          vc4-hdmi-0 HDMI Jack
/d         input3          input          vc4-hdmi-1
/e         input4          input          vc4-hdmi-1 HDMI Jack
/f         eth0            network        Ethernet interface
/10        eth1            network        Ethernet interface
/11        eth2            network        Ethernet interface
```


## inxi summary (optional)

```
System:
  Kernel: 6.12.34+rpt-rpi-v8 arch: aarch64 bits: 32 compiler: N/A
    parameters: reboot=w coherent_pool=1M 8250.nr_uarts=1 pci=pcie_bus_safe
    cgroup_disable=memory numa_policy=interleave nvme.max_host_mem_size_mb=0
    numa=fake=8 system_heap.max_order=0 smsc95xx.macaddr=[IPv6-redacted]xx:xx:xx
    vc_mem.mem_base=0x3fc00000 vc_mem.mem_size=0x40000000
    console=ttyAMA10,115200 console=tty1 root=PARTUUID=28076b05-02
    rootfstype=ext4 fsck.repair=yes rootwait quiet splash
    plymouth.ignore-serial-consoles cfg80211.ieee80211_regdom=GB
  Console: pty pts/0 DM: LightDM v: 1.26.0 Distro: Raspbian GNU/Linux 12
    (bookworm)
Machine:
  Type: ARM System: Raspberry Pi 5 Model B Rev 1.0 details: N/A rev: d04170
    serial: <filter>
CPU:
  Info: model: N/A variant: cortex-a76 bits: 64 type: MCP arch: ARMv8 family: 8
    model-id: 4 stepping: 1
  Topology: cpus: 1x cores: 4 smt: <unsupported> cache: L1: 512 KiB
    desc: d-4x64 KiB; i-4x64 KiB L2: 2 MiB desc: 4x512 KiB L3: 2 MiB
    desc: 1x2 MiB
  Speed (MHz): avg: 2400 min/max: 1500/2400 scaling: driver: cpufreq-dt
    governor: ondemand cores: 1: 2400 2: 2400 3: 2400 4: 2400 bogomips: 432
  Features: Use -f option to see features
  Vulnerabilities:
  Type: gather_data_sampling status: Not affected
  Type: indirect_target_selection status: Not affected
  Type: itlb_multihit status: Not affected
  Type: l1tf status: Not affected
  Type: mds status: Not affected
  Type: meltdown status: Not affected
  Type: mmio_stale_data status: Not affected
  Type: reg_file_data_sampling status: Not affected
  Type: retbleed status: Not affected
  Type: spec_rstack_overflow status: Not affected
  Type: spec_store_bypass mitigation: Speculative Store Bypass disabled via
    prctl
  Type: spectre_v1 mitigation: __user pointer sanitization
  Type: spectre_v2 mitigation: CSV2, BHB
  Type: srbds status: Not affected
  Type: tsx_async_abort status: Not affected
Graphics:
  Device-1: bcm2712-hdmi0 driver: vc4_hdmi v: N/A bus-ID: N/A
    chip-ID: brcm:107c701400 class-ID: hdmi
  Device-2: bcm2712-hdmi1 driver: vc4_hdmi v: N/A bus-ID: N/A
    chip-ID: brcm:107c706400 class-ID: hdmi
  Display: wayland server: X.org v: 1.21.xx.xx with: Xwayland v: 22.1.9
    compositor: LabWC driver:
    gpu: vc4-drm,vc4_crtc,vc4_dpi,vc4_dsi,vc4_firmware_kms,vc4_hdmi,vc4_hvs,vc4_txp,vc4_v3d,vc4_vec
    tty: 117x62
  Monitor-1: HDMI-A-2 model: ViewSonic VP2468 Series serial: <filter>
    built: 2017 res: 1920x1080 dpi: 93 gamma: 1.2 size: 527x296mm (20.75x11.65")
    diag: 604mm (23.8") ratio: 16:9 modes: max: 1920x1080 min: 720x400
  API: EGL/GBM Message: No known Wayland EGL/GBM data sources.
Audio:
  Device-1: bcm2712-hdmi0 driver: vc4_hdmi bus-ID: N/A chip-ID: brcm:107c701400
    class-ID: hdmi
  Device-2: bcm2712-hdmi1 driver: vc4_hdmi bus-ID: N/A
    chip-ID: brcm:107c706400 class-ID: hdmi
  API: ALSA v: k6.12.34+rpt-rpi-v8 status: kernel-api tools: alsamixer,amixer
  Server-1: PipeWire v: 1.2.7 status: active with: 1: pipewire-pulse
    status: active 2: wireplumber status: active tools: pw-cat,pw-cli,wpctl
  Server-2: PulseAudio v: 16.1 status: off (using pipewire-pulse)
    tools: pacat,pactl
Network:
  Device-1: Raspberry Pi RP1 PCIe 2.0 South Bridge driver: rp1 v: kernel
    port: N/A bus-ID: [IPv6-redacted].0 chip-ID: 1de4:0001 class-ID: 0200
  IF: wlan0 state: up mac: <filter>
  Device-2: Realtek RTL8153 Gigabit Ethernet Adapter type: USB driver: r8152
    bus-ID: 2-1:2 chip-ID: 0bda:8153 class-ID: 0000 serial: <filter>
  IF: eth2 state: down mac: <filter>
  Device-3: Realtek RTL8153 Gigabit Ethernet Adapter type: USB driver: r8152
    bus-ID: 4-1:2 chip-ID: 0bda:8153 class-ID: 0000 serial: <filter>
  IF: eth1 state: down mac: <filter>
  IF-ID-1: br0 state: down mac: <filter>
  IF-ID-2: eth0 state: down mac: <filter>
Bluetooth:
  Device-1: bcm7271-uart driver: bcm7271_uart bus-ID: N/A
    chip-ID: brcm:107d50c000 class-ID: serial
  Report: hciconfig ID: hci0 rfk-id: 0 state: up address: <filter> bt-v: 3.0
    lmp-v: 5.0 sub-v: 6119 hci-v: 5.0 rev: 17e
  Info: acl-mtu: 1021:8 sco-mtu: 64:1 link-policy: rswitch sniff
    link-mode: peripheral accept service-classes: rendering, capturing, audio,
    telephony
Drives:
  Local Storage: total: 233.2 GiB used: 5.54 GiB (2.4%)
  SMART Message: Required tool smartctl not installed. Check --recommends
  ID-1: /dev/mmcblk0 maj-min: 179:0 type: Removable model: USD00
    size: 233.2 GiB block-size: physical: 512 B logical: 512 B type: SSD
    serial: <filter> scheme: MBR
Partition:
  ID-1: / raw-size: 232.7 GiB size: 229.01 GiB (98.42%) used: 5.43 GiB (2.4%)
    fs: ext4 dev: /dev/mmcblk0p2 maj-min: 179:2
Swap:
  Kernel: swappiness: 60 (default) cache-pressure: 100 (default)
  ID-1: swap-1 type: file size: 200 MiB used: 0 KiB (0.0%) priority: -2
    file: /var/swap
Sensors:
  System Temperatures: cpu: 57.8 C mobo: N/A
  Fan Speeds (RPM): cpu: 2017
Info:
  Processes: 210 Uptime: 2h 11m Memory: 7.77 GiB used: 433.8 MiB (5.5%)
  gpu: 8 MiB Init: systemd v: 252 target: graphical (5) default: graphical
  tool: systemctl Compilers: gcc: 12.2.0 alt: 12 Packages: pm: dpkg pkgs: 1651
  libs: 869 tools: apt,apt-get Shell: Bash v: 5.2.15
  running-in: pty pts/0 (SSH) inxi: 3.3.26
```


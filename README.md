# tc-menu v2.4

Menu-driven `tc/netem` controller for inline L2 bridges (Raspberry Pi friendly).

Menu map
1–10: Preset profiles (1–9) and 10 = Custom NETEM (with validation)
11: Dry-run mode toggle (no changes applied; commands are printed)
12: Offload toggler (TSO/GSO/GRO on/off for eth1/eth2)
13: Show counters (Δ since last apply/reset)
14: Show rich status (qdiscs, DSCP filters if present)
15: Reset ALL (clears both NICs; and IFB if enabled)
16: Show counters (absolute + Δ)
17: Scenarios (timed sequences, including app-aware DSCP sets)
18: Ingress (IFB) apply … (visible only if USE_IFB=1)
19: DSCP-targeted impairment (ON/OFF + decoded summary)
20: TTL watchdog / “until HH:MM” auto-clear
0: Exit

Per-profile workflow (1–10)
1.	Select a profile.
2.	Select Direction
o	1) LAN→WAN = apply on WAN_IF egress (default eth2)
o	2) WAN→LAN = apply on LAN_IF egress (default eth1)
o	3) BOTH = apply to both
3.	Select Action
o	ON = apply (existing qdisc on that path is cleared first)
o	OFF = clear only that path
4.	Status and counters are displayed and logged.

Profile notes
•	6 = Custom rate limit (TBF) → prompts for rate / burst / latency with input validation and a suggested burst based on rate.
•	When RATE_CAP is set, all NETEM profiles (except #6) are wrapped as: HTB(root, rate/burst) → class 1:1 → child NETEM.
•	“Wireless-ish” and similar presets automatically add distribution normal when supported (detected at start).

Custom NETEM (option 10)
•	Accepts free-form netem arguments (e.g., delay 120ms 30ms loss 0.5% reorder 2% 30%) and validates them on lo before applying.

DSCP-targeted impairment (option 19)
•	Builds prio 1: with child netem and u32 DSCP filters (IPv4).
•	Status includes a decoded list such as 34 (AF41, TOS 0x88), 46 (EF, TOS 0xb8) and the child stack details.

Scenarios (option 17)
•	Provides timed, ready-made conditions (Minor/Mild/Medium/Severe/Blackout) and app-aware flows (Teams / Amazon Connect).
•	A countdown runs during each scenario; r aborts (with auto-clear), q exits.

Ingress shaping with IFB (option 18)
•	Enabled by launching with USE_IFB=1.
•	Applies custom NETEM on ingress by redirecting ethX ingress to ifb0 and shaping its egress.


## Run
```bash
sudo /usr/local/sbin/tc-menu.sh
```

## License
MIT (see `LICENSE`).

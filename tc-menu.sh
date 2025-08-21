# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Jose Carvalho
# Project: https://github.com/zearthlink/tc-menu

#!/usr/bin/env bash
# tc-menu v2.4
set -Euo pipefail

VERSION="v2.4"
AUTHOR_SIG="Made by Jose Carvalho CCIE#46666 (with AI coding help)"

# ====== CONFIG ======
LAN_IF="${LAN_IF:-eth1}"   # LAN side of your inline bridge
WAN_IF="${WAN_IF:-eth2}"   # WAN side of your inline bridge

# Optional global rate-cap wrapper (if set): HTB(rate/burst) -> class 1:1 -> child NETEM
RATE_CAP="${RATE_CAP:-}"              # e.g., "5mbit" or "512kbit" (unset/empty disables wrapper)
RATE_BURST="${RATE_BURST:-64kb}"      # HTB burst; bytes-based units recommended
RATE_LATENCY="${RATE_LATENCY:-400ms}" # informational only (used in prompts)

LOG_FILE="${LOG_FILE:-/var/log/tc-menu.log}"

# Feature flag: IFB/ingress support (hidden/disabled by default)
USE_IFB="${USE_IFB:-0}"   # 0=hide IFB/ingress menu & avoid ifb module, 1=enable

# App-aware DSCP defaults (decimal). Typical mapping: Teams/AC Audio=EF(46), Video=AF41(34)
TEAMS_AUDIO_DSCP="${TEAMS_AUDIO_DSCP:-46}"
TEAMS_VIDEO_DSCP="${TEAMS_VIDEO_DSCP:-34}"
TEAMS_SHARE_DSCP="${TEAMS_SHARE_DSCP:-18}"

AC_AUDIO_DSCP="${AC_AUDIO_DSCP:-46}"
AC_VIDEO_DSCP="${AC_VIDEO_DSCP:-34}"

# ====== GLOBALS ======
DRY_RUN="${DRY_RUN:-0}"  # 0=apply, 1=print-only

# ====== LOGGING ======
timestamp() { date +'%Y-%m-%d %H:%M:%S%z'; }
log()  { printf '%s %s\n' "$(timestamp)" "$*" | tee -a "$LOG_FILE" >/dev/null 2>&1 || true; }
warn() { log "WARN: $*"; printf 'WARN: %s\n' "$*" >&2; }
die()  { log "ERROR: $*"; printf 'ERROR: %s\n' "$*" >&2; exit 1; }

init_log() {
  mkdir -p "$(dirname "$LOG_FILE")"
  touch "$LOG_FILE" 2>/dev/null || true
  chmod 0644 "$LOG_FILE" 2>/dev/null || true
  log "==== tc-menu $VERSION started (LAN_IF=$LAN_IF WAN_IF=$WAN_IF RATE_CAP=${RATE_CAP:-none} DRY_RUN=$DRY_RUN IFB=$USE_IFB) ===="
}

# Exit + signal handling
trap 'rc=$?; log "ERROR trap (rc=$rc) on line $LINENO"' ERR
trap 'log "EXIT"; echo "'"$AUTHOR_SIG"'"' EXIT
trap 'log "SIGINT received"; exit 130' INT
trap 'log "SIGTERM received"; exit 143' TERM

# ====== REQUIREMENTS ======
need_root() { [ "$EUID" -eq 0 ] || die "Run as root (sudo)."; }
check_cmds() {
  command -v tc >/dev/null || die "tc not found"
  command -v ip >/dev/null || die "ip not found"
  command -v awk >/dev/null || die "awk not found"
  command -v ethtool >/dev/null || warn "ethtool not found; offload toggle will be unavailable"
}
ensure_modules() {
  modprobe sch_netem 2>/dev/null || true
  modprobe sch_htb  2>/dev/null || true
  [ "$USE_IFB" = "1" ] && modprobe ifb 2>/dev/null || true
}

# ====== SAFETY WRAPPERS ======
tc_do() {
  if [ "$DRY_RUN" = "1" ]; then
    echo "DRY-RUN: tc $*" | tee -a "$LOG_FILE" >/dev/null
    return 0
  fi
  local out rc
  out="$(tc "$@" 2>&1)"; rc=$?
  if [ $rc -ne 0 ]; then
    warn "tc $* failed (rc=$rc): $out"
    # Never propagate non-zero; keep the menu alive
    return 0
  fi
  return 0
}

# Run a function safely: disable errexit + ERR inheritance during call, then restore
run_safe() {
  local _old="$-"
  set +e +E
  "$@"; local rc=$?
  [[ "$_old" == *E* ]] && set -E || set +E
  [[ "$_old" == *e* ]] && set -e || true
  return $rc
}

# ====== IF HELPERS ======
if_exists() { ip link show "$1" >/dev/null 2>&1; }
if_exists_or_warn() { if if_exists "$1"; then return 0; else warn "Interface $1 not found; skipping"; return 1; fi; }
note_if_missing() { if ! if_exists "$1"; then warn "Interface $1 not found at startup"; fi; }

clear_dev() {
  local dev="$1"
  if ! if_exists_or_warn "$dev"; then return 0; fi
  tc_do qdisc del dev "$dev" root 2>/dev/null || true
  tc_do qdisc del dev "$dev" ingress 2>/dev/null || true
  log "Cleared qdisc on $dev"
}
clear_all() {
  clear_dev "$LAN_IF"; clear_dev "$WAN_IF"
  [ "$USE_IFB" = "1" ] && tc_do qdisc del dev ifb0 root 2>/dev/null || true
}

# --- Rich status helpers (Option 19 aware) ---

summarize_device() {
  local dev="$1"
  echo "== $dev =="
  if if_exists "$dev"; then
    ip -br link show "$dev" 2>&1 | sed 's/^/ /' | tee -a "$LOG_FILE" || true

    # full qdisc tree
    local qdisc_out
    qdisc_out="$(tc -s qdisc show dev "$dev" 2>/dev/null)"
    printf "%s\n" "$qdisc_out" | sed 's/^/ /' | tee -a "$LOG_FILE" || true

    # If this looks like Option 19 / DSCP-targeted stack, show more
    if printf "%s" "$qdisc_out" | grep -qE 'qdisc[[:space:]]+prio[[:space:]]+1:'; then
      echo "---- parent 1:1 child on $dev ----"
      printf "%s\n" "$qdisc_out" | grep -E 'qdisc (netem|tbf|htb).*parent 1:1' | sed 's/^/ /' | tee -a "$LOG_FILE" || true
      show_filters_parent1 "$dev"
    fi
  else
    echo " (not found)"
  fi
}

# --- DSCP name map (common codepoints) ---
dscp_name() {
  case "$1" in
    0)  echo "BE" ;;
    8)  echo "CS1" ;; 16) echo "CS2" ;; 24) echo "CS3" ;;
    32) echo "CS4" ;; 40) echo "CS5" ;; 48) echo "CS6" ;; 56) echo "CS7" ;;
    10) echo "AF11" ;; 12) echo "AF12" ;; 14) echo "AF13" ;;
    18) echo "AF21" ;; 20) echo "AF22" ;; 22) echo "AF23" ;;
    26) echo "AF31" ;; 28) echo "AF32" ;; 30) echo "AF33" ;;
    34) echo "AF41" ;; 36) echo "AF42" ;; 38) echo "AF43" ;;
    46) echo "EF"   ;;
    *)  echo "-"    ;;
  esac
}

# Pretty format: "34 (AF41, TOS 0x88), 46 (EF, TOS 0xb8)"
format_dscp_targets_pretty() {
  local out=() d tos_hex
  for d in "$@"; do
    printf -v tos_hex "0x%02x" $(( d << 2 ))
    out+=( "$(printf '%s (%s, TOS %s)' "$d" "$(dscp_name "$d")" "$tos_hex")" )
  done
  ((${#out[@]})) && printf '%s\n' "$(IFS=', '; echo "${out[*]}")"
}

# Extract unique DSCPs (decimal) from IPv4 u32 filters under parent 1:
# Handles both:
#   match 00880000/00fc0000 at 0
#   match ip tos 0x88 0xfc
extract_dscp_list_ipv4() {
  local dev="$1" line hex mask tos_hex dscp
  local seen=() dscps=()

  while IFS= read -r line; do
    line="${line,,}"  # lowercase
    # Form 1: compiled 32-bit u32 match (mask 00fc0000, second byte is TOS)
    if [[ $line =~ match[[:space:]]([0-9a-f]{8})/([0-9a-f]{8}) ]]; then
      hex="${BASH_REMATCH[1]}"
      mask="${BASH_REMATCH[2]}"
      if [[ "$mask" == "00fc0000" ]]; then
        tos_hex="${hex:2:2}"                         # second byte
        dscp=$(( (16#$tos_hex) >> 2 ))
        if [[ -z "${seen[$dscp]+x}" ]]; then seen[$dscp]=1; dscps+=("$dscp"); fi
      fi
      continue
    fi
    # Form 2: textual tos
    if [[ $line =~ match[[:space:]]ip[[:space:]]tos[[:space:]]0x([0-9a-f]{2})[[:space:]]0xfc ]]; then
      tos_hex="${BASH_REMATCH[1]}"
      dscp=$(( (16#$tos_hex) >> 2 ))
      if [[ -z "${seen[$dscp]+x}" ]]; then seen[$dscp]=1; dscps+=("$dscp"); fi
      continue
    fi
  done < <(tc -s filter show dev "$dev" parent 1: 2>/dev/null)

  printf '%s\n' "${dscps[@]}"
}

netem_child_line() {
  local dev="$1"
  tc -s qdisc show dev "$dev" 2>/dev/null | grep -E 'qdisc (netem|tbf|htb).*parent 1:1' | head -n1
}

show_filters_parent1() {
  local dev="$1"
  echo "---- filters (parent 1:) on $dev ----"
  tc -s filter show dev "$dev" parent 1: 2>/dev/null | sed 's/^/ /' | tee -a "$LOG_FILE" || true

  # Collect DSCPs without using 'mapfile'
  local dscps=() d
  while IFS= read -r d; do [ -n "$d" ] && dscps+=("$d"); done < <(extract_dscp_list_ipv4 "$dev")

  if ((${#dscps[@]})); then
    echo " [decoded DSCP targets]: $(format_dscp_targets_pretty "${dscps[@]}")"
    local child; child="$(netem_child_line "$dev")"
    [ -n "$child" ] && echo " [scope]: IPv4 packets with those DSCPs → parent 1:1 → ${child#qdisc }"
  fi
}

summarize_device() {
  local dev="$1"
  echo "== $dev =="
  if if_exists "$dev"; then
    ip -br link show "$dev" 2>&1 | sed 's/^/ /' | tee -a "$LOG_FILE" || true

    local qdisc_out
    qdisc_out="$(tc -s qdisc show dev "$dev" 2>/dev/null)"
    printf "%s\n" "$qdisc_out" | sed 's/^/ /' | tee -a "$LOG_FILE" || true

    # If prio 1: present, show its child and DSCP filters
    if printf "%s" "$qdisc_out" | grep -qE 'qdisc[[:space:]]+prio[[:space:]]+1:'; then
      echo "---- parent 1:1 child on $dev ----"
      netem_child_line "$dev" | sed 's/^/ /' | tee -a "$LOG_FILE" || true
      show_filters_parent1 "$dev"
    fi
  else
    echo " (not found)"
  fi
}


# ====== NETEM capability check ======
NETEM_DIST_FLAG=()
detect_netem_distribution() {
  if [ "$DRY_RUN" = "1" ]; then NETEM_DIST_FLAG=(); log "Skip 'distribution normal' check (dry-run)"; return; fi
  if tc qdisc add dev lo root netem delay 1ms distribution normal 2>/dev/null; then
    tc qdisc del dev lo root 2>/dev/null || true
    NETEM_DIST_FLAG=(distribution normal)
    log "NETEM 'distribution normal' supported"
  else
    NETEM_DIST_FLAG=(); log "NETEM 'distribution normal' not supported"
  fi
}

# ====== MENU TEXT ======
profile_name() {
  case "$1" in
    1) echo "Delay 200ms ±50ms";;
    2) echo "Loss 3%";;
    3) echo "Corrupt 0.2%";;
    4) echo "Duplicate 1%";;
    5) echo "Reorder 25% (50% corr) + 10ms";;
    6) echo "Custom rate limit (TBF — prompt for rate/burst/latency)";;
    7) echo "Wireless-ish: 100ms ±30ms, loss 1%, dup 0.5%, reorder 5% (50%)";;
    8) echo "Burst loss 5% (25% corr)";;
    9) echo "Delay 100ms ±20ms, loss 2%, reorder 25% (50%), gap 5";;
    10) echo "Custom NETEM (free-form; validated)";;
    *) echo "Unknown";;
  esac
}

# ====== HTB + NETEM APPLY ======
apply_netem_or_child() {
  local dev="$1"; shift
  if ! if_exists_or_warn "$dev"; then return 0; fi
  tc_do qdisc del dev "$dev" root 2>/dev/null || true
  if [ -n "${RATE_CAP:-}" ]; then
    tc_do qdisc add dev "$dev" root handle 1: htb default 1
    tc_do class add dev "$dev" parent 1: classid 1:1 htb rate "$RATE_CAP" burst "$RATE_BURST"
    tc_do qdisc add dev "$dev" parent 1:1 handle 10: netem "$@"
    log "Applied HTB(rate=$RATE_CAP burst=$RATE_BURST) + NETEM($*) on $dev"
  else
    tc_do qdisc add dev "$dev" root netem "$@"
    log "Applied NETEM($*) on $dev"
  fi
}

apply_profile_to_dev() {
  local idx="$1" dev="$2"
  if ! if_exists_or_warn "$dev"; then return 0; fi
  clear_dev "$dev"
  case "$idx" in
    1) apply_netem_or_child "$dev" delay 200ms 50ms ;;
    2) apply_netem_or_child "$dev" loss 3% ;;
    3) apply_netem_or_child "$dev" corrupt 0.2% ;;
    4) apply_netem_or_child "$dev" duplicate 1% ;;
    5) apply_netem_or_child "$dev" delay 10ms reorder 25% 50% ;;
    6) local r="${TBF_R:-${RATE_CAP:-512kbit}}"
       local b="${TBF_B:-$(default_burst_for_profile6)}"
       local l="${TBF_L:-${RATE_LATENCY:-400ms}}"
       tc_do qdisc add dev "$dev" root tbf rate "$r" burst "$b" latency "$l"
       log "Applied TBF(rate=$r burst=$b latency=$l) on $dev"
       ;;
    7) apply_netem_or_child "$dev" delay 100ms 30ms "${NETEM_DIST_FLAG[@]}" loss 1% duplicate 0.5% reorder 5% 50% ;;
    8) apply_netem_or_child "$dev" loss 5% 25% ;;
    9) apply_netem_or_child "$dev" delay 100ms 20ms "${NETEM_DIST_FLAG[@]}" loss 2% reorder 25% 50% gap 5 ;;
    99) apply_netem_or_child "$dev" ${CUSTOM_NETEM_ARGS[@]+"${CUSTOM_NETEM_ARGS[@]}"} ;;
    *) die "Unknown profile index: $idx" ;;
  esac
}

apply_direction() {
  local idx="$1" dir="$2" # 1=LAN->WAN, 2=WAN->LAN, 3=both
  case "$dir" in
    1) log "Apply profile $idx ($(profile_name "$idx")) to LAN->WAN (egress $WAN_IF)"; apply_profile_to_dev "$idx" "$WAN_IF" ;;
    2) log "Apply profile $idx ($(profile_name "$idx")) to WAN->LAN (egress $LAN_IF)"; apply_profile_to_dev "$idx" "$LAN_IF" ;;
    3) log "Apply profile $idx ($(profile_name "$idx")) to BOTH directions"; apply_profile_to_dev "$idx" "$LAN_IF"; apply_profile_to_dev "$idx" "$WAN_IF" ;;
    *) echo "Invalid direction choice"; return 1 ;;
  esac
}

clear_direction() {
  local dir="$1"
  case "$dir" in
    1) log "Clear LAN->WAN (egress $WAN_IF)"; clear_dev "$WAN_IF" ;;
    2) log "Clear WAN->LAN (egress $LAN_IF)"; clear_dev "$LAN_IF" ;;
    3) log "Clear BOTH directions"; clear_dev "$LAN_IF"; clear_dev "$WAN_IF" ;;
    *) echo "Invalid direction choice"; return 1 ;;
  esac
}

# ====== INGRESS (IFB) – gated by USE_IFB ======
ensure_ifb() { ip link show ifb0 >/dev/null 2>&1 || ip link add ifb0 type ifb; ip link set ifb0 up || true; }
attach_ingress_to_ifb() { local dev="$1"; tc_do qdisc del dev "$dev" ingress 2>/dev/null || true; tc_do qdisc add dev "$dev" handle ffff: ingress; tc_do filter add dev "$dev" parent ffff: protocol all u32 match u32 0 0 action mirred egress redirect dev ifb0; log "Redirected ingress of $dev to ifb0"; }
apply_ingress_netem() { [ "$USE_IFB" = "1" ] || { warn "IFB disabled"; return 1; }; ensure_ifb; attach_ingress_to_ifb "$1"; shift; tc_do qdisc del dev ifb0 root 2>/dev/null || true; tc_do qdisc add dev ifb0 root netem "$@"; log "Applied NETEM($*) on ingress via ifb0"; }

# ====== DSCP-TARGETED (u32) ======
# Convert decimal DSCP to TOS hex + mask (0xfc)
dscp_hex() { printf "0x%02x 0xfc" $(( ($1 & 0x3f) << 2 )); }
# Try 'tos' first, fall back to 'dsfield' (some tc builds prefer it)
add_dscp_filter() { # dev, tos_hex, mask_hex
  local dev="$1" tos="$2" mask="$3"
  tc_do filter add dev "$dev" protocol ip  parent 1: prio 1 u32 match ip tos "$tos" "$mask"        flowid 1:1
  tc_do filter add dev "$dev" protocol ip  parent 1: prio 1 u32 match ip dsfield "$tos" "$mask"    flowid 1:1
}

apply_netem_multi_dscp_u32() { # dev, "46,34", ...netem args...
  local dev="$1" lst="$2"; shift 2
  if ! if_exists_or_warn "$dev"; then return 0; fi
  clear_dev "$dev"
  tc_do qdisc add dev "$dev" root handle 1: prio bands 3
  tc_do qdisc add dev "$dev" parent 1:1 handle 10: netem "$@"
  local ds tos mask
  for ds in $(echo "$lst" | tr ',' ' '); do
    read tos mask < <(dscp_hex "$ds")
    add_dscp_filter "$dev" "$tos" "$mask"
  done
  log "Applied NETEM($*) on $dev for DSCPs=[$lst]"
}

netem_child_replace() { local dev="$1"; shift; tc_do qdisc replace dev "$dev" parent 1:1 handle 10: netem "$@"; }

# ====== STATUS & COUNTERS ======
show_status() {
  echo
  echo "========== STATUS ($VERSION) =========="
  echo "LAN_IF=$LAN_IF WAN_IF=$WAN_IF"
  echo "Dry-run: $([ "$DRY_RUN" = "1" ] && echo ON || echo OFF)"
  if [ -n "$RATE_CAP" ]; then
    echo "Global rate-cap wrapper: HTB rate=$RATE_CAP burst=$RATE_BURST + child NETEM"
  else
    echo "Global rate-cap wrapper: disabled"
  fi
  echo "----------------------------"
  echo "Interfaces:"
  for dev in "$LAN_IF" "$WAN_IF"; do
    if if_exists "$dev"; then ip -br link show "$dev" 2>&1 | sed 's/^/ /' || true; else echo " $dev: (not found)"; fi
  done
  echo "----------------------------"

  # Rich per-device summaries (qdiscs + decoded DSCP if present)
  summarize_device "$LAN_IF"
  echo "----------------------------"
  summarize_device "$WAN_IF"

  # IFB (if enabled & present)
  if [ "$USE_IFB" = "1" ] && ip link show ifb0 >/dev/null 2>&1; then
    echo "----------------------------"
    echo "== ifb0 =="
    ip -br link show ifb0 2>&1 | sed 's/^/ /' | tee -a "$LOG_FILE" || true
    tc -s qdisc show dev ifb0 2>/dev/null | sed 's/^/ /' | tee -a "$LOG_FILE" || true
  fi

  echo "============================"
  log "Status shown (rich)"
}

# mawk-compatible counters
get_counters() {
  local dev="$1"
  if ! if_exists "$dev"; then echo "0 0"; return; fi
  tc -s qdisc show dev "$dev" 2>/dev/null | awk '
  {
    for (i = 1; i <= NF; i++) {
      t = $i; gsub(/^[()]+/,"",t); gsub(/[,:)]*$/,"",t)
      if (t == "dropped") d += $(i+1) + 0
      else if (t == "overlimits") o += $(i+1) + 0
    }
  }
  END { if (d == "") d = 0; if (o == "") o = 0; print d, o }'
}

declare -A SNAP_DROP SNAP_OVL
snapshot_counters() {
  local d o
  read d o < <(get_counters "$LAN_IF"); SNAP_DROP["$LAN_IF"]=$d; SNAP_OVL["$LAN_IF"]=$o
  read d o < <(get_counters "$WAN_IF"); SNAP_DROP["$WAN_IF"]=$d; SNAP_OVL["$WAN_IF"]=$o
  log "Counters snapshot updated"
}
show_counters() {
  echo
  echo "======== COUNTERS (since last apply/reset) ========"
  for dev in "$LAN_IF" "$WAN_IF"; do
    if ! if_exists "$dev"; then echo " $dev: (not found)"; continue; fi
    local curD curO prevD prevO dD dO
    read curD curO < <(get_counters "$dev")
    prevD="${SNAP_DROP[$dev]:-0}"; prevO="${SNAP_OVL[$dev]:-0}"
    dD=$(( curD - prevD )); dO=$(( curO - prevO ))
    printf " %-6s dropped: %d (Δ %d) overlimits: %d (Δ %d)\n" "$dev" "$curD" "$dD" "$curO" "$dO"
  done
  echo "==================================================="
}
show_counters_abs_and_delta() {
  echo
  echo "==== COUNTERS (absolute | Δ since snapshot) ===="
  for dev in "$LAN_IF" "$WAN_IF"; do
    if ! if_exists "$dev"; then echo " $dev: (not found)"; continue; fi
    local curD curO prevD prevO dD dO
    read curD curO < <(get_counters "$dev")
    prevD="${SNAP_DROP[$dev]:-0}"; prevO="${SNAP_OVL[$dev]:-0}"
    dD=$(( curD - prevD )); dO=$(( curO - prevO ))
    printf " %-6s dropped: %d | Δ %d    overlimits: %d | Δ %d\n" "$dev" "$curD" "$dD" "$curO" "$dO"
  done
  echo "==============================================="
}

# ====== OFFLOAD TOGGLER ======
toggle_offloads() {
  local mode="$1" # off|on
  if ! command -v ethtool >/dev/null; then warn "ethtool not available"; return; fi
  for dev in "$LAN_IF" "$WAN_IF"; do
    if if_exists "$dev"; then
      ethtool -K "$dev" gro "$mode" gso "$mode" tso "$mode" 2>/dev/null \
        && log "Set offloads $mode on $dev" || warn "Could not set offloads $mode on $dev"
    else
      warn "Interface $dev not found; cannot toggle offloads"
    fi
  done
}
ask_offloads_menu() {
  local k
  while :; do
    echo
    echo "Offload toggler (TSO/GSO/GRO):"
    echo " 1) OFF"
    echo " 2) ON"
    read -rp "Choose [1-2] (q to exit): " k || true
    case "$k" in
      q|Q) return ;;
      1) toggle_offloads off; return ;;
      2) toggle_offloads on;  return ;;
      *) echo "Invalid choice";;
    esac
  done
}

# ====== DRY-RUN MENU ======
ask_dryrun_menu() {
  local k
  while :; do
    echo
    echo "Dry-run mode (no changes applied). Currently: $([ "$DRY_RUN" = "1" ] && echo ON || echo OFF)"
    echo " 1) ON"
    echo " 2) OFF"
    read -rp "Choose [1-2] (q to exit): " k || true
    case "$k" in
      q|Q) return ;;
      1) DRY_RUN=1; log "Dry-run enabled";  return ;;
      2) DRY_RUN=0; log "Dry-run disabled"; return ;;
      *) echo "Invalid choice";;
    esac
  done
}

# ====== PROFILE 6 (Dynamic TBF) helpers ======
to_lc_nospace() { local x="${*}"; x="${x,,}"; x="${x//[[:space:]]/}"; echo "$x"; }
norm_rate() { local x; x="$(to_lc_nospace "$1")"; x="${x/kbps/kbit}"; x="${x/mbps/mbit}"; x="${x/gbps/gbit}"; echo "$x"; }
is_valid_rate(){ local x; x="$(norm_rate "$1")"; [[ "$x" =~ ^[0-9]+(kbit|mbit|gbit|bit|bps)$ ]]; }
norm_burst() { local x; x="$(to_lc_nospace "$1")"; x="${x/bytes/b}"; x="${x/byte/b}"; echo "$x"; }
is_valid_burst(){ local x; x="$(norm_burst "$1")"; [[ "$x" =~ ^[0-9]+(b|kb|mb|gb|kib|mib|gib|k|m|g)$ ]]; }
norm_latency(){ to_lc_nospace "$1"; }
is_valid_latency(){ local x; x="$(norm_latency "$1")"; [[ "$x" =~ ^[0-9]+(ns|us|ms|s)$ ]]; }

rate_to_bps() {
  local x; x="$(norm_rate "$1")"
  if [[ "$x" =~ ^([0-9]+)(gbit|mbit|kbit|bit|bps)$ ]]; then
    local n="${BASH_REMATCH[1]}" u="${BASH_REMATCH[2]}"
    case "$u" in
      gbit) echo $(( n * 1000000000 ));;
      mbit) echo $(( n * 1000000 ));;
      kbit) echo $(( n * 1000 ));;
      bit|bps) echo $(( n ));;
    esac
    return 0
  fi
  echo 0
}
suggest_burst_from_rate() { local bps; bps="$(rate_to_bps "$1")"; [ "$bps" -gt 0 ] || { echo "512kb"; return; }; local bytes=$(( bps / 8 / 40 )); local step=4096; bytes=$(( ( (bytes + step - 1) / step ) * step )); echo "${bytes}b"; }
default_burst_for_profile6() { local raw="${RATE_BURST:-}"; if [ -z "$raw" ]; then echo "512kb"; return; fi; local nb="$(norm_burst "$raw")"; if is_valid_burst "$nb"; then echo "$nb"; else echo "512kb"; fi; }
prompt_until_valid_var() {
  local __var="$1" label="$2" def="$3" validator="$4" normalizer="$5" examples="$6"
  local inp norm
  while :; do
    read -rp "Enter ${label} [default: ${def}] (q to exit): " inp || true
    case "$inp" in q|Q) return 1 ;; esac
    inp="${inp:-$def}"
    norm="$("$normalizer" "$inp")"
    if "$validator" "$norm"; then printf -v "$__var" '%s' "$norm"; return 0
    else echo " -> Invalid ${label}. Examples: ${examples}"; fi
  done
}
TBF_R=""; TBF_B=""; TBF_L=""
ask_tbf_params() {
  local def_r="${RATE_CAP:-512kbit}" def_b="$(default_burst_for_profile6)" def_l="${RATE_LATENCY:-400ms}"
  echo; echo "===== Profile 6: Custom Rate Limit (TBF) ====="
  prompt_until_valid_var TBF_R "RATE" "$def_r" is_valid_rate norm_rate "500mbit, 100mbit, 1gbit, 500mbps" || return 1
  local suggested; suggested="$(suggest_burst_from_rate "$TBF_R")"; echo "Suggested BURST ≈ $suggested (~25ms)"; def_b="$suggested"
  prompt_until_valid_var TBF_B "BURST" "$def_b" is_valid_burst norm_burst "512kb, 1mb, 65536b" || return 1
  prompt_until_valid_var TBF_L "LATENCY" "$def_l" is_valid_latency norm_latency "50ms, 200ms, 1s" || return 1
  echo "Selected: rate=$TBF_R, burst=$TBF_B, latency=$TBF_L"
  return 0
}

# ====== CUSTOM NETEM ======
CUSTOM_NETEM_ARGS=()
validate_netem_args() {
  local _old="$-" rc out
  set +e +E
  tc qdisc del dev lo root >/dev/null 2>&1
  out="$(tc qdisc add dev lo root netem "$@" 2>&1)"; rc=$?
  [ $rc -eq 0 ] && tc qdisc del dev lo root >/dev/null 2>&1
  [[ "$_old" == *E* ]] && set -E || set +E
  [[ "$_old" == *e* ]] && set -e || true
  printf '%s' "$out"; return $rc
}
ask_custom_netem() {
  echo; echo "===== Custom NETEM ====="
  local line out
  while :; do
    read -rp "NETEM args (q to exit): " line || true
    case "$line" in q|Q) return 1 ;; esac
    [ -z "$line" ] && { echo " -> Empty input. Try again."; continue; }
    # shellcheck disable=SC2206
    local args=( $line )
    if [ "$DRY_RUN" = "1" ]; then CUSTOM_NETEM_ARGS=( "${args[@]}" ); echo "Accepted (dry-run): ${CUSTOM_NETEM_ARGS[*]}"; return 0; fi
    if out="$(validate_netem_args "${args[@]}")"; then CUSTOM_NETEM_ARGS=( "${args[@]}" ); echo "Accepted: ${CUSTOM_NETEM_ARGS[*]}"; return 0
    else echo " -> Invalid NETEM args. Kernel says:"; echo " $out"; fi
  done
}

# ====== COUNTDOWN / ABORT ======
countdown() {
  # $1=seconds  $2=label  $3..=devs to clear on abort
  local sec="$1" label="$2"; shift 2
  local devs=( "$@" )
  local t key
  # Shield from ERR/errexit regardless of caller
  local _old="$-"; set +e +E
  for ((t=sec; t>0; t--)); do
    printf "\r%s: %4ds remaining  [press 'r' to abort, 'q' to exit]" "$label" "$t"
    read -t 1 -n 1 key 2>/dev/null || true
    case "${key:-}" in
      r|R) echo; for d in "${devs[@]}"; do clear_dev "$d"; done; log "Scenario aborted by user"; [[ "$_old" == *E* ]] && set -E || set +E; [[ "$_old" == *e* ]] && set -e || true; return 1 ;;
      q|Q) echo; [[ "$_old" == *E* ]] && set -E || set +E; [[ "$_old" == *e* ]] && set -e || true; exit 0 ;;
      *) : ;;
    esac
  done
  echo
  [[ "$_old" == *E* ]] && set -E || set +E
  [[ "$_old" == *e* ]] && set -e || true
  return 0
}

# ====== DEV/SCENARIO HELPERS ======
devs_from_dir() {
  local dir="$1"
  case "$dir" in
    1) echo "$WAN_IF" ;;
    2) echo "$LAN_IF" ;;
    3) echo "$LAN_IF $WAN_IF" ;;
  esac
}

scenario_apply_and_wait() {
  # $1=dir  $2=seconds  $3=label  $4..=netem args
  local dir="$1" sec="$2" label="$3"; shift 3
  local args=( "$@" )
  local devs; read -r -a devs <<<"$(devs_from_dir "$dir")"
  for d in "${devs[@]}"; do apply_netem_or_child "$d" "${args[@]}"; done
  countdown "$sec" "$label" "${devs[@]}" || return 1
  for d in "${devs[@]}"; do clear_dev "$d"; done
  log "$label complete"
  return 0
}

scenario_minor()  { scenario_apply_and_wait "$1" "${2:-180}" "Scenario MINOR"  delay 40ms 10ms "${NETEM_DIST_FLAG[@]}"; }
scenario_mild()   { scenario_apply_and_wait "$1" "${2:-180}" "Scenario MILD"   delay 80ms 20ms "${NETEM_DIST_FLAG[@]}" loss 0.5% reorder 2% 30%; }
scenario_severe() { scenario_apply_and_wait "$1" "${2:-180}" "Scenario SEVERE" delay 180ms 60ms "${NETEM_DIST_FLAG[@]}" loss 2.5% reorder 12% 50% gap 5; }
scenario_medium() {
  local dir="$1" dur="${2:-240}"
  local devs; read -r -a devs <<<"$(devs_from_dir "$dir")"
  for d in "${devs[@]}"; do apply_netem_or_child "$d" delay 120ms 30ms "${NETEM_DIST_FLAG[@]}" loss 1% reorder 5% 30%; done
  countdown $((dur/2)) "Scenario MEDIUM (phase 1)" "${devs[@]}" || return 1
  for d in "${devs[@]}"; do netem_child_replace "$d" delay 120ms 30ms "${NETEM_DIST_FLAG[@]}" loss 1.5% reorder 8% 40%; done
  countdown $((dur - dur/2)) "Scenario MEDIUM (phase 2)" "${devs[@]}" || return 1
  for d in "${devs[@]}"; do clear_dev "$d"; done
  log "Scenario MEDIUM complete"
  return 0
}

scenario_blackout_storm() {
  local dir="$1" repeats="${2:-3}" hold="${3:-6}" gap="${4:-20}"
  local devs; read -r -a devs <<<"$(devs_from_dir "$dir")"
  local i
  for ((i=1;i<=repeats;i++)); do
    for d in "${devs[@]}"; do tc_do qdisc replace dev "$d" root netem loss 100%; done
    countdown "$hold" "BLACKOUT ($i/$repeats)" "${devs[@]}" || return 1
    for d in "${devs[@]}"; do tc_do qdisc del dev "$d" root 2>/dev/null || true; done
    if [ "$i" -lt "$repeats" ]; then countdown "$gap" "LINK UP gap" "${devs[@]}" || return 1; fi
  done
  log "Scenario BLACKOUT-STORM complete"
  return 0
}

# ====== APP-AWARE SCENARIOS (DSCP-targeted) ======
scenario_apply_dscp_and_wait() {
  # $1=dir  $2=seconds  $3=label  $4=dscp_list_csv  $5..=netem args
  local dir="$1" sec="$2" label="$3" dscps="$4"; shift 4
  local args=( "$@" )
  local devs; read -r -a devs <<<"$(devs_from_dir "$dir")"
  for d in "${devs[@]}"; do apply_netem_multi_dscp_u32 "$d" "$dscps" "${args[@]}"; done
  countdown "$sec" "$label" "${devs[@]}" || return 1
  for d in "${devs[@]}"; do clear_dev "$d"; done
  log "$label complete"
  return 0
}

scenario_teams_voice() { scenario_apply_dscp_and_wait "$1" "${2:-180}" "TEAMS VOICE (EF=$TEAMS_AUDIO_DSCP)"  "$TEAMS_AUDIO_DSCP"           delay 30ms 10ms "${NETEM_DIST_FLAG[@]}" loss 0.5% reorder 1% 20%; }
scenario_teams_video() { scenario_apply_dscp_and_wait "$1" "${2:-180}" "TEAMS VIDEO (AF41=$TEAMS_VIDEO_DSCP)" "$TEAMS_VIDEO_DSCP"           delay 50ms 20ms "${NETEM_DIST_FLAG[@]}" loss 0.7% reorder 2% 30%; }
scenario_teams_both()  { scenario_apply_dscp_and_wait "$1" "${2:-240}" "TEAMS VOICE+VIDEO"                     "$TEAMS_AUDIO_DSCP,$TEAMS_VIDEO_DSCP" delay 45ms 15ms "${NETEM_DIST_FLAG[@]}" loss 0.6% reorder 2% 30%; }

scenario_ac_voice()   { scenario_apply_dscp_and_wait "$1" "${2:-180}" "AMAZON CONNECT VOICE (EF=$AC_AUDIO_DSCP)"  "$AC_AUDIO_DSCP"           delay 35ms 12ms "${NETEM_DIST_FLAG[@]}" loss 0.5% reorder 1% 20%; }
scenario_ac_video()   { scenario_apply_dscp_and_wait "$1" "${2:-180}" "AMAZON CONNECT VIDEO (AF41=$AC_VIDEO_DSCP)" "$AC_VIDEO_DSCP"           delay 60ms 25ms "${NETEM_DIST_FLAG[@]}" loss 0.8% reorder 3% 30%; }
scenario_ac_both()    { scenario_apply_dscp_and_wait "$1" "${2:-240}" "AMAZON CONNECT VOICE+VIDEO"               "$AC_AUDIO_DSCP,$AC_VIDEO_DSCP" delay 55ms 20ms "${NETEM_DIST_FLAG[@]}" loss 0.7% reorder 2% 30%; }

# ====== SUMMARIES ======
post_apply_summary_for_dir() {
  local dir="$1" devs
  read -r -a devs <<<"$(devs_from_dir "$dir")"
  echo
  echo "====== POST-APPLY SUMMARY (Option 19) ======"
  for d in "${devs[@]}"; do
    echo "== $d qdisc =="
    tc -s qdisc show dev "$d" 2>/dev/null | sed 's/^/ /' | tee -a "$LOG_FILE" || true
    # Use the ROBUST show_filters_parent1 (the one that decodes DSCP + scope)
    show_filters_parent1 "$d"
  done
  echo "==========================================="
  log "Option 19 post-apply summary shown"
}

run_scenario_menu() {
  local k dir dur rc devs
  while :; do
    echo
    echo "Scenarios:"
    echo " 1) Minor"
    echo " 2) Mild"
    echo " 3) Medium (two-phase)"
    echo " 4) Severe"
    echo " 5) Blackout storm (flaps)"
    echo "---- Application-aware (DSCP-targeted) ----"
    echo " 6) Teams Voice only     (EF=$TEAMS_AUDIO_DSCP)"
    echo " 7) Teams Video only     (AF41=$TEAMS_VIDEO_DSCP)"
    echo " 8) Teams Voice + Video"
    echo " 9) Amazon Connect Softphone (EF=$AC_AUDIO_DSCP)"
    echo "10) Amazon Connect Video     (AF41=$AC_VIDEO_DSCP)"
    echo "11) Amazon Connect Voice + Video"
    echo " 0) Back"
    read -rp "Choose [0-11]: " k || true
    case "$k" in
      0) return ;;
      *)
        read_direction; dir="$REPLY"
        case "$k" in
          1) read -rp "Duration seconds [default 180]: " dur || true; dur="${dur:-180}"
             run_safe scenario_minor  "$dir" "$dur";  rc=$? ;;
          2) read -rp "Duration seconds [default 180]: " dur || true; dur="${dur:-180}"
             run_safe scenario_mild   "$dir" "$dur";  rc=$? ;;
          3) read -rp "Duration seconds [default 240]: " dur || true; dur="${dur:-240}"
             run_safe scenario_medium "$dir" "$dur";  rc=$? ;;
          4) read -rp "Duration seconds [default 180]: " dur || true; dur="${dur:-180}"
             run_safe scenario_severe "$dir" "$dur";  rc=$? ;;
          5) read -rp "Repeats [3], Hold(s) [6], Gap(s) [20]: " a b c || true
             run_safe scenario_blackout_storm "$dir" "${a:-3}" "${b:-6}" "${c:-20}"; rc=$? ;;
          6) read -rp "Duration seconds [default 180]: " dur || true; dur="${dur:-180}"
             run_safe scenario_teams_voice "$dir" "$dur"; rc=$? ;;
          7) read -rp "Duration seconds [default 180]: " dur || true; dur="${dur:-180}"
             run_safe scenario_teams_video "$dir" "$dur"; rc=$? ;;
          8) read -rp "Duration seconds [default 240]: " dur || true; dur="${dur:-240}"
             run_safe scenario_teams_both  "$dir" "$dur"; rc=$? ;;
          9) read -rp "Duration seconds [default 180]: " dur || true; dur="${dur:-180}"
             run_safe scenario_ac_voice    "$dir" "$dur"; rc=$? ;;
         10) read -rp "Duration seconds [default 180]: " dur || true; dur="${dur:-180}"
             run_safe scenario_ac_video    "$dir" "$dur"; rc=$? ;;
         11) read -rp "Duration seconds [default 240]: " dur || true; dur="${dur:-240}"
             run_safe scenario_ac_both     "$dir" "$dur"; rc=$? ;;
          *) echo "Invalid choice"; rc=0 ;;
        esac
        if [ "${rc:-0}" -ne 0 ]; then
          echo "Scenario aborted/failed (rc=$rc). Clearing impairments…"
          read -r -a devs <<<"$(devs_from_dir "$dir")"
          for d in "${devs[@]}"; do clear_dev "$d"; done
          snapshot_counters
          show_status
        fi
        ;;
    esac
  done
}

# ====== INPUT HELPERS ======
read_main_choice() {
  local k
  while :; do
    echo
    echo "======== Impairment Profiles ========"
    for i in {1..10}; do printf "%2d) %s\n" "$i" "$(profile_name "$i")"; done
    echo "-------------------------------------"
    echo "11) Dry-run mode … (currently: $([ "$DRY_RUN" = "1" ] && echo ON || echo OFF))"
    echo "12) Offload toggler (TSO/GSO/GRO) …"
    echo "13) Show counters (Δ since last apply/reset)"
    echo "14) Show status"
    echo "15) Reset ALL (clear $LAN_IF and $WAN_IF)"
    echo "16) Show counters (ABS + Δ)"
    echo "17) Run scenarios …"
    [ "$USE_IFB" = "1" ] && echo "18) Apply on ingress (IFB) …"
    echo "19) DSCP-targeted impairment … (ON/OFF + summary)"
    echo "20) Start TTL watchdog … / Until HH:MM …"
    echo " 0) Exit"
    read -rp "Choose [0-20] (q to exit): " k || true
    case "$k" in
      q|Q) exit 0 ;;
      0|[1-9]|1[0-9]|20) REPLY="$k"; return ;;
      *) echo "Invalid choice";;
    esac
  done
}
read_direction() {
  local k
  while :; do
    echo
    echo "Direction:"
    echo " 1) LAN -> WAN (apply on $WAN_IF egress)"
    echo " 2) WAN -> LAN (apply on $LAN_IF egress)"
    echo " 3) BOTH directions"
    read -rp "Choose [1-3] (q to exit): " k || true
    case "$k" in q|Q) exit 0 ;; [1-3]) REPLY="$k"; return ;; *) echo "Invalid choice";; esac
  done
}
read_action() {
  local k
  while :; do
    echo
    echo "Action:"
    echo " 1) ON (apply this profile)"
    echo " 2) OFF (clear for selected direction)"
    read -rp "Choose [1-2] (q to exit): " k || true
    case "$k" in q|Q) exit 0 ;; [1-2]) REPLY="$k"; return ;; *) echo "Invalid choice";; esac
  done
}

# ====== TTL WATCHDOG & ABSOLUTE UNTIL ======
start_ttl_watchdog() {
  local span="${1:-30m}"
  pkill -f "tc-menu-ttl-watchdog" 2>/dev/null || true
  (
    sleep "${span}"
    /sbin/tc qdisc del dev "$LAN_IF" root 2>/dev/null || true
    /sbin/tc qdisc del dev "$WAN_IF" root 2>/dev/null || true
    [ "$USE_IFB" = "1" ] && /sbin/tc qdisc del dev ifb0 root 2>/dev/null || true
    logger -t tc-menu-ttl-watchdog "Auto-cleared after ${span}" 2>/dev/null || true
  ) >/dev/null 2>&1 &
  disown
  log "TTL watchdog set: ${span}"
}
ttl_until() { local when="$1"; local now_s target_s; now_s=$(date +%s); target_s=$(date -d "$(date +%F) $when" +%s 2>/dev/null || true); [ -z "${target_s:-}" ] && { warn "Invalid time '$when'"; return 1; }; [ "$target_s" -le "$now_s" ] && target_s=$((target_s+86400)); local span=$((target_s-now_s)); log "TTL until $when (in ${span}s)"; start_ttl_watchdog "${span}s"; }

# ====== MAIN ======
need_root
check_cmds
ensure_modules
note_if_missing "$LAN_IF"; note_if_missing "$WAN_IF"
init_log
detect_netem_distribution
snapshot_counters

echo "tc-menu $VERSION: LAN_IF=$LAN_IF, WAN_IF=$WAN_IF"
[ -n "$RATE_CAP" ] && echo "Rate-cap mode: root HTB (rate=$RATE_CAP burst=$RATE_BURST) + child NETEM"
echo "Dry-run: $([ "$DRY_RUN" = "1" ] && echo ON || echo OFF)"
echo "IFB/ingress menu: $([ "$USE_IFB" = "1" ] && echo ENABLED || echo HIDDEN)"
echo "Log: $LOG_FILE"

while true; do
  read_main_choice; choice="$REPLY"
  case "$choice" in
    0) log "Exit requested"; exit 0 ;;

    11) ask_dryrun_menu; show_status; continue ;;
    12) ask_offloads_menu; show_status; continue ;;
    13) show_counters; continue ;;
    14) show_status; continue ;;
    15) echo "Resetting ALL qdisc on $LAN_IF and $WAN_IF..."; log "Reset ALL"; clear_all; snapshot_counters; show_status; continue ;;
    16) show_counters_abs_and_delta; continue ;;
    17) run_scenario_menu; continue ;;
    18)
      if [ "$USE_IFB" != "1" ]; then echo "IFB/ingress disabled (set USE_IFB=1)"; continue; fi
      echo "Apply on ingress (IFB) to which direction?"; read_direction; dir="$REPLY"
      run_safe ask_custom_netem; rc=$?
      [ $rc -ne 0 ] && { echo "Cancelled."; continue; }
      case "$dir" in
        1) run_safe apply_ingress_netem "$WAN_IF" ${CUSTOM_NETEM_ARGS[@]+"${CUSTOM_NETEM_ARGS[@]}"} ;;
        2) run_safe apply_ingress_netem "$LAN_IF" ${CUSTOM_NETEM_ARGS[@]+"${CUSTOM_NETEM_ARGS[@]}"} ;;
        3) run_safe apply_ingress_netem "$LAN_IF" ${CUSTOM_NETEM_ARGS[@]+"${CUSTOM_NETEM_ARGS[@]}"}; run_safe apply_ingress_netem "$WAN_IF" ${CUSTOM_NETEM_ARGS[@]+"${CUSTOM_NETEM_ARGS[@]}"} ;;
      esac
      snapshot_counters; show_status; continue
      ;;
    19)
      read_direction; dir="$REPLY"
      read_action; action="$REPLY"
      case "$action" in
        1)  # ON
            read -rp "DSCP(s) to target (CSV) [default: $TEAMS_AUDIO_DSCP]: " dval || true
            dval="${dval:-$TEAMS_AUDIO_DSCP}"
            run_safe ask_custom_netem; rc=$?
            [ $rc -ne 0 ] && { echo "Cancelled."; continue; }
            case "$dir" in
              1) run_safe apply_netem_multi_dscp_u32 "$WAN_IF" "$dval" ${CUSTOM_NETEM_ARGS[@]+"${CUSTOM_NETEM_ARGS[@]}"} ;;
              2) run_safe apply_netem_multi_dscp_u32 "$LAN_IF" "$dval" ${CUSTOM_NETEM_ARGS[@]+"${CUSTOM_NETEM_ARGS[@]}"} ;;
              3) run_safe apply_netem_multi_dscp_u32 "$LAN_IF" "$dval" ${CUSTOM_NETEM_ARGS[@]+"${CUSTOM_NETEM_ARGS[@]}"}; run_safe apply_netem_multi_dscp_u32 "$WAN_IF" "$dval" ${CUSTOM_NETEM_ARGS[@]+"${CUSTOM_NETEM_ARGS[@]}"} ;;
            esac
            snapshot_counters
            post_apply_summary_for_dir "$dir"
            ;;
        2)  # OFF
            clear_direction "$dir"
            snapshot_counters
            post_apply_summary_for_dir "$dir"
            ;;
      esac
      continue
      ;;
    20)
      echo "TTL/Until:"
      echo " 1) Start TTL watchdog (minutes or Ns/Nm format)"
      echo " 2) Set TTL until HH:MM (24h local)"
      read -rp "Choose [1-2]: " k || true
      case "$k" in
        1) read -rp "Enter TTL span (e.g., 20m, 900s): " span || true; [ -n "${span:-}" ] && start_ttl_watchdog "$span" ;;
        2) read -rp "Enter time (HH:MM): " hhmm || true; [ -n "${hhmm:-}" ] && ttl_until "$hhmm" ;;
      esac
      continue
      ;;
    10)
      run_safe ask_custom_netem; rc=$?
      [ $rc -ne 0 ] && { echo "Cancelled."; continue; }
      echo "Selected: [10] $(profile_name 10)"
      read_direction; dir="$REPLY"
      read_action; action="$REPLY"
      case "$action" in
        1) echo "Applying 'Custom NETEM' (dir=$dir) ..."; log "Apply: profile=10 name='Custom NETEM' dir=$dir args='${CUSTOM_NETEM_ARGS[*]}'"; run_safe apply_direction 99 "$dir"; snapshot_counters ;;
        2) echo "Clearing qdisc for chosen direction..."; log "Clear: dir=$dir"; clear_direction "$dir"; snapshot_counters ;;
      esac
      show_status
      ;;
    [1-9])
      prof_name="$(profile_name "$choice")"
      echo "Selected: [$choice] $prof_name"
      read_direction; dir="$REPLY"
      read_action; action="$REPLY"
      case "$action" in
        1) [ "$choice" -eq 6 ] && { run_safe ask_tbf_params || { echo "Cancelled."; continue; }; }
           echo "Applying '$prof_name' (dir=$dir) ..."
           log "Apply: profile=$choice name='$prof_name' dir=$dir"
           run_safe apply_direction "$choice" "$dir"
           [ "$choice" -eq 6 ] && { TBF_R=""; TBF_B=""; TBF_L=""; }
           snapshot_counters ;;
        2) echo "Clearing qdisc for chosen direction..."; log "Clear: dir=$dir"; clear_direction "$dir"; snapshot_counters ;;
      esac
      show_status
      ;;
    *) echo "Invalid choice"; log "Invalid menu choice: $choice";;
  esac
done

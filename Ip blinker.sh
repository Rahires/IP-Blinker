#!/bin/bash
# ==========================================================
# IP BLINKER - Simple Tor IP Changer
# Author  : Sahebrao Rahire
# Year    : 2026
# License : GNU GPL v2
# ==========================================================
# Educational use only.
# ==========================================================

# ── Config ─────────────────────────────────────────────────
TOR_PROXY="127.0.0.1:9050"
IP_API="https://api.ipify.org"
CHANGE_INTERVAL=45   # seconds between IP changes
TOR_BOOT_WAIT=10     # seconds to wait after tor restart

# ── Colors ─────────────────────────────────────────────────
R='\033[0;31m'  # Red
G='\033[0;32m'  # Green
Y='\033[1;33m'  # Yellow
C='\033[0;36m'  # Cyan
B='\033[1;34m'  # Blue
NC='\033[0m'    # Reset

# ── Logging ────────────────────────────────────────────────
info()    { echo -e "${C}[*]${NC} $1"; }
success() { echo -e "${G}[✓]${NC} $1"; }
warn()    { echo -e "${Y}[!]${NC} $1"; }
error()   { echo -e "${R}[✗]${NC} $1"; exit 1; }

# ── Banner ─────────────────────────────────────────────────
banner() {
  clear
  echo -e "${B}"
  echo "  ╔══════════════════════════════════════╗"
  echo "  ║       IP BLINKER - Tor IP Changer    ║"
  echo "  ║         Author: Sahebrao Rahire       ║"
  echo "  ╚══════════════════════════════════════╝"
  echo -e "${NC}"
}

# ── Root Check ─────────────────────────────────────────────
check_root() {
  [ "$(id -u)" -eq 0 ] || error "Run with sudo: sudo ./ip_blinker.sh"
}

# ── Install Missing Tools ──────────────────────────────────
install_deps() {
  local missing=""
  command -v curl >/dev/null 2>&1 || missing="$missing curl"
  command -v tor  >/dev/null 2>&1 || missing="$missing tor"

  [ -z "$missing" ] && return

  info "Installing:$missing"
  apt-get update -qq && apt-get install -y $missing -qq
  success "Dependencies installed"
}

# ── Tor Service Control ────────────────────────────────────
start_tor() {
  systemctl is-active --quiet tor && return
  info "Starting Tor..."
  systemctl enable --now tor >/dev/null 2>&1
  sleep 5
  systemctl is-active --quiet tor || error "Tor failed to start"
  success "Tor is running"
}

# ── Test Tor Proxy ─────────────────────────────────────────
test_tor() {
  info "Verifying Tor connection..."
  local i=1
  while [ "$i" -le 3 ]; do
    if curl -s --socks5-hostname "$TOR_PROXY" --max-time 15 "$IP_API" >/dev/null 2>&1; then
      success "Tor connection OK"
      return 0
    fi
    warn "Attempt $i/3 failed — retrying..."
    systemctl restart tor >/dev/null 2>&1
    sleep 5
    i=$((i + 1))
  done
  error "Cannot connect through Tor after 3 attempts"
}

# ── Fetch IP via Tor ───────────────────────────────────────
get_ip() {
  curl -s --socks5-hostname "$TOR_PROXY" --max-time 15 "$IP_API" 2>/dev/null || echo "UNKNOWN"
}

# ── Change Tor Circuit (new IP) ────────────────────────────
new_circuit() {
  systemctl restart tor >/dev/null 2>&1
  sleep "$TOR_BOOT_WAIT"
}

# ── Divider ────────────────────────────────────────────────
divider() { echo -e "${B}  ──────────────────────────────────────${NC}"; }

# ── Graceful Exit ──────────────────────────────────────────
cleanup() {
  echo
  info "Stopped by user. Goodbye!"
  exit 0
}

# ── Main ───────────────────────────────────────────────────
main() {
  trap cleanup SIGINT SIGTERM

  banner
  check_root
  install_deps
  start_tor
  test_tor

  echo
  echo -e "  ${G}READY!${NC} Proxy → ${C}${TOR_PROXY}${NC}"
  echo -e "  Changing IP every ${Y}${CHANGE_INTERVAL}s${NC} | Press ${R}Ctrl+C${NC} to stop"
  divider

  local count=0

  while true; do
    count=$((count + 1))
    echo
    echo -e "  ${C}Round #${count}${NC}"

    # Get current IP before change
    OLD_IP=$(get_ip)
    echo -e "  👀 Old IP → ${Y}${OLD_IP}${NC}"

    # Request new circuit
    info "Switching Tor circuit..."
    new_circuit

    # Get new IP after change
    NEW_IP=$(get_ip)
    echo -e "  ✨ New IP → ${G}${NEW_IP}${NC}"

    # Compare old and new IP
    if [ "$OLD_IP" = "UNKNOWN" ] || [ "$NEW_IP" = "UNKNOWN" ]; then
      warn "Could not fetch IP — Tor may still be booting"
    elif [ "$OLD_IP" = "$NEW_IP" ]; then
      warn "IP unchanged — Tor reused the circuit"
    else
      success "IP changed successfully!"
    fi

    divider
    echo -e "  ⏳ Next change in ${CHANGE_INTERVAL}s..."
    sleep "$CHANGE_INTERVAL"
  done
}

main "$@"

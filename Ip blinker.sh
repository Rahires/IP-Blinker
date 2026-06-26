#!/bin/bash

# ==========================================================
# IP BLINKER - Simple Tor IP Changer
# Author  : Sahebrao Rahire
# Year    : 2026
# License : GNU GPL v2
# ==========================================================
#
# ---------------------- LICENSE NOTICE ---------------------
#
# Copyright (c) 2026 Sahebrao Rahire
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Full license:
# [gnu.org](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
#
# ---------------------- DISCLAIMER -------------------------
#
# Educational use only.
#
# ==========================================================

set -euo pipefail

TOR_HOST="127.0.0.1"
TOR_PORT="9050"
URL="[api.ipify.org](https://api.ipify.org)"
WAIT_INTERVAL=45
TOR_RESTART_WAIT=10

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_banner() {
  clear
  echo -e "${CYAN}"
  echo "=========================================="
  echo "         IP BLINKER - Tor IP Changer     "
  echo "=========================================="
  echo -e "${NC}"
  echo "Educational use only"
  echo
}

log_info()    { echo -e "${CYAN}[*]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
log_error()   { echo -e "${RED}[✗]${NC} $1"; }

check_root() {
  if [[ $EUID -ne 0 ]]; then
    log_error "This script requires root privileges. Run with sudo."
    exit 1
  fi
}

install_dependencies() {
  local packages=()

  if ! command -v curl >/dev/null 2>&1; then
    packages+=(curl)
  fi

  if ! command -v tor >/dev/null 2>&1; then
    packages+=(tor)
  fi

  if [[ ${#packages[@]} -gt 0 ]]; then
    log_info "Installing dependencies: ${packages[*]}..."
    apt update -qq
    apt install -y "${packages[@]}"
  fi
}

start_tor() {
  if ! systemctl is-active --quiet tor; then
    log_info "Starting Tor service..."
    systemctl enable --now tor
    sleep 5
  fi
}

test_tor_connection() {
  log_info "Testing Tor connection..."
  local attempts=3

  for ((i=1; i<=attempts; i++)); do
    if curl -s --socks5-hostname "${TOR_HOST}:${TOR_PORT}" --max-time 15 "$URL" >/dev/null 2>&1; then
      log_success "Tor connection verified"
      return 0
    fi
    log_warn "Attempt $i/$attempts failed, retrying..."
    systemctl restart tor
    sleep 5
  done

  log_error "Could not establish Tor connection after $attempts attempts"
  exit 1
}

get_ip() {
  curl -s --socks5-hostname "${TOR_HOST}:${TOR_PORT}" --max-time 20 "$URL" 2>/dev/null || echo "UNKNOWN"
}

change_ip() {
  systemctl restart tor
  sleep "$TOR_RESTART_WAIT"
}

cleanup() {
  echo
  log_info "Shutting down..."
  exit 0
}

main() {
  trap cleanup SIGINT SIGTERM

  print_banner
  check_root
  install_dependencies
  start_tor
  test_tor_connection

  echo
  echo -e "${GREEN}READY!${NC} Using Tor via ${TOR_HOST}:${TOR_PORT}"
  echo "Press Ctrl+C to stop"
  echo "=========================================="

  while true; do
    echo
    log_info "Fetching current IP..."
    OLD_IP=$(get_ip)
    echo -e "    👀 Current IP: ${YELLOW}${OLD_IP}${NC}"

    log_info "Requesting new Tor circuit..."
    change_ip

    NEW_IP=$(get_ip)
    echo -e "    ✨ New IP:     ${YELLOW}${NEW_IP}${NC}"

    if [[ "$OLD_IP" == "UNKNOWN" || "$NEW_IP" == "UNKNOWN" ]]; then
      log_warn "Could not fetch IP (Tor may still be initializing)"
    elif [[ "$OLD_IP" != "$NEW_IP" ]]; then
      log_success "IP changed successfully!"
    else
      log_warn "IP unchanged (may need more time)"
    fi

    echo -e "    ⏳ Next change in ${WAIT_INTERVAL}s..."
    sleep "$WAIT_INTERVAL"
  done
}

main "$@"

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
# version 2 as published by the Free Software Foundation.[web:77]
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# Full license text:
# https://www.gnu.org/licenses/old-licenses/gpl-2.0.html
#
# ---------------------- DISCLAIMER -------------------------
#
# This script routes traffic through the Tor network and attempts
# to change the visible IP address by restarting the Tor service.
#
# It is intended for EDUCATIONAL USE ONLY (e.g., lab experiments,
# privacy study). Using Tor or changing IPs for illegal or
# unauthorized activities may violate laws and site policies.[web:69][web:72]
#
# The author is NOT responsible for any misuse, damage, or legal
# issues caused by this script. Use it only on systems and networks
# where you have permission, and follow all applicable laws.
#
# ==========================================================

set -euo pipefail

TOR="127.0.0.1:9050"
URL="https://api.ipify.org"  # simple public IP service[web:104]

clear
echo "=== IP BLINKER ==="
echo "Tor IP changer (educational use only)"
echo

# Ensure wget
if ! command -v wget >/dev/null 2>&1; then
  echo "[*] Installing wget..."
  sudo apt update && sudo apt install -y wget
fi

# Ensure Tor
if ! systemctl is-active tor >/dev/null 2>&1; then
  echo "[*] Installing/starting Tor..."
  sudo apt update && sudo apt install -y tor
  sudo systemctl start tor
fi

# Quick Tor test (through Tor SOCKS)
echo "[*] Testing Tor..."
wget -qO- --proxy=on \
  --execute="use_proxy=yes;https_proxy=socks5h://$TOR" \
  "$URL" >/dev/null 2>&1 || sudo systemctl restart tor[web:80][web:87]

echo
echo "READY! Using Tor via $TOR  |  Press Ctrl+C to stop"
echo "==============================================="

get_ip() {
  wget -qO- --proxy=on \
    --execute="use_proxy=yes;https_proxy=socks5h://$TOR" \
    "$URL" 2>/dev/null || echo "UNKNOWN"
}

while true; do
  echo
  echo "👀 OLD IP:"
  OLD=$(get_ip)
  echo "$OLD"

  echo "🔄 Restarting Tor..."
  sudo systemctl restart tor
  sleep 8

  echo "✨ NEW IP:"
  NEW=$(get_ip)
  echo "$NEW"

  [[ "$OLD" != "$NEW" ]] && echo "✅ CHANGED!" || echo "⚠️ Same IP"
  echo "⏳ Wait 45s..."
  sleep 45
done

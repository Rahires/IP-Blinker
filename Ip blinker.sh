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
# https://www.gnu.org/licenses/old-licenses/gpl-2.0.html
#
# ---------------------- DISCLAIMER -------------------------
#
# Educational use only.
#
# ==========================================================

set -euo pipefail

TOR="127.0.0.1:9050"
URL="https://api.ipify.org"

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
if ! systemctl is-active --quiet tor; then
  echo "[*] Installing/starting Tor..."
  sudo apt update && sudo apt install -y tor
  sudo systemctl enable --now tor
fi

echo "[*] Testing Tor..."

# FIX: correct SOCKS usage
wget -qO- \
  --proxy=on \
  --execute="https_proxy=socks5h://$TOR" \
  "$URL" >/dev/null 2>&1 || {
    echo "[!] Tor not ready, restarting..."
    sudo systemctl restart tor
    sleep 5
}

echo
echo "READY! Using Tor via $TOR | Ctrl+C to stop"
echo "==============================================="

get_ip() {
  wget -qO- \
    --proxy=on \
    --execute="https_proxy=socks5h://$TOR" \
    "$URL" 2>/dev/null || echo "UNKNOWN"
}

while true; do
  echo
  echo "👀 OLD IP:"
  OLD=$(get_ip)
  echo "$OLD"

  echo "🔄 Restarting Tor..."
  sudo systemctl restart tor
  sleep 10

  echo "✨ NEW IP:"
  NEW=$(get_ip)
  echo "$NEW"

  if [[ "$OLD" == "UNKNOWN" || "$NEW" == "UNKNOWN" ]]; then
    echo "⚠️ Could not fetch IP (Tor not ready yet)"
  elif [[ "$OLD" != "$NEW" ]]; then
    echo "✅ CHANGED!"
  else
    echo "⚠️ Same IP"
  fi

  echo "⏳ Wait 45s..."
  sleep 45
done

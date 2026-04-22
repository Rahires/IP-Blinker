#!/bin/bash
# IP BLINKER - Simple Tor IP Changer
# Student Project - Changes IP every 45s

clear
echo "=== IP BLINKER ==="
echo "Auto Tor IP changer for students"

# STEP 1: Check tools
echo "1️⃣ Checking tools..."
command -v curl >/dev/null || sudo apt install -y curl
systemctl is-active tor >/dev/null || {
  sudo apt install -y tor
  sudo systemctl start tor
}

# STEP 2: Test Tor
echo "2️⃣ Testing Tor..."
curl -s --socks5 127.0.0.1:9050 http://ifconfig.me >/dev/null || sudo systemctl restart tor

echo "✅ READY! Ctrl+C to stop"
echo "=================="

# MAIN LOOP - Easy!
while true; do
  echo -e "\n👀 OLD IP:"
  OLD=$(curl -s --socks5 127.0.0.1:9050 http://ifconfig.me)
  echo "$OLD"
  
  echo "🔄 CHANGING..."
  sudo systemctl restart tor
  sleep 8
  
  echo "✨ NEW IP:"
  NEW=$(curl -s --socks5 127.0.0.1:9050 http://ifconfig.me)
  echo "$NEW"
  
  [[ $OLD != $NEW ]] && echo "✅ CHANGED!" || echo "⚠️ Same IP"
  echo "⏳ 45s pause..."
  sleep 45
done

# IP Blinker — Tor IP Changer

> Author : Sahebrao Rahire (2026)  
> License : GNU GPL v2

A lightweight Bash script that automatically rotates your public IP address  
by cycling through Tor exit nodes at a set interval. Built for privacy research,  
network education, and understanding how the Tor anonymity network works.

---

## Script

| File | Description |
|---|---|
| `ip_blinker.sh` | Main script — auto-rotates IP via Tor SOCKS5 proxy |

---

## How It Works

```
Your Machine → Tor Entry Node → Middle Node → Exit Node → Internet
                                                   ↑
                                       This IP is what sites see
```

Every time the script restarts Tor, it builds a **new circuit** through  
different relay nodes, which gives you a new exit IP address.  
The script fetches your current IP before and after each change  
so you can confirm the rotation worked.

---

## Features

- Auto-installs `tor` and `curl` if not present
- Starts and enables the Tor service automatically
- Tests the Tor SOCKS5 connection before entering the loop
- Fetches current IP via Tor before and after each rotation
- Compares old vs new IP and reports success or failure
- Colored terminal output for easy reading
- Round counter so you can track how many rotations have happened
- Graceful Ctrl+C exit with a clean shutdown message
- Configurable interval and boot wait at the top of the script

---

## Requirements

| Tool | Purpose | Install |
|---|---|---|
| `bash` | Script interpreter | Pre-installed on Kali |
| `tor` | Anonymity proxy network | Auto-installed by script |
| `curl` | Fetch public IP via Tor | Auto-installed by script |
| `systemctl` | Start/restart Tor service | Pre-installed on Kali |

> The script auto-installs `tor` and `curl` if they are missing — no manual setup needed.

---

## Installation

### Step 1 — Clone the repository

```bash
git clone https://github.com/Rahires/ip-blinker.git
cd ip-blinker
```

### Step 2 — Make the script executable

```bash
chmod +x ip_blinker.sh
```

### Step 3 — Run it

```bash
sudo ./ip_blinker.sh
```

> Always use `sudo ./` — never `sudo sh ./` which ignores the `#!/bin/bash`  
> shebang and uses `dash` instead, causing syntax errors.

---

## Usage

```bash
sudo ./ip_blinker.sh
```

**What you will see:**

```
  ╔══════════════════════════════════════╗
  ║       IP BLINKER - Tor IP Changer    ║
  ║         Author: Sahebrao Rahire       ║
  ╚══════════════════════════════════════╝

[✓] Nmap is ready
[*] Starting Tor...
[✓] Tor is running
[*] Verifying Tor connection...
[✓] Tor connection OK

  READY! Proxy → 127.0.0.1:9050
  Changing IP every 45s | Press Ctrl+C to stop
  ──────────────────────────────────────

  Round #1
  👀 Old IP → 185.220.101.45
  [*] Switching Tor circuit...
  ✨ New IP → 93.174.93.12
  [✓] IP changed successfully!
  ──────────────────────────────────────
  ⏳ Next change in 45s...
```

Press **Ctrl+C** at any time to stop cleanly.

---

## Configuration

All timing settings are at the top of the script and easy to change:

```bash
# ── Config ─────────────────────────────────────────────────
TOR_PROXY="127.0.0.1:9050"     # Tor SOCKS5 proxy address (don't change)
IP_API="https://api.ipify.org"  # Public IP lookup API (don't change)
CHANGE_INTERVAL=45              # Seconds between IP rotations
TOR_BOOT_WAIT=10                # Seconds to wait after Tor restarts
```

| Setting | Default | Notes |
|---|---|---|
| `CHANGE_INTERVAL` | `45` | Lower = faster rotations. Min ~30s recommended |
| `TOR_BOOT_WAIT` | `10` | Don't go below 5 — Tor needs time to build a circuit |
| `TOR_PROXY` | `127.0.0.1:9050` | Tor's default SOCKS5 address — don't change |

---

## Manual Steps (Without the Script)

If you want to understand what the script does manually:

```bash
# 1. Install Tor
sudo apt-get install -y tor curl

# 2. Start Tor
sudo systemctl start tor

# 3. Check your IP through Tor
curl --socks5-hostname 127.0.0.1:9050 https://api.ipify.org

# 4. Get a new IP (restart Tor circuit)
sudo systemctl restart tor
sleep 10

# 5. Check new IP
curl --socks5-hostname 127.0.0.1:9050 https://api.ipify.org
```

---

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `Permission denied` | Not using sudo | Run with `sudo ./ip_blinker.sh` |
| `bad syntax` on line 68 | Running with `sh` instead of `bash` | Use `sudo ./` not `sudo sh ./` |
| IP shows `UNKNOWN` | Tor still bootstrapping | Wait one full cycle — it self-recovers |
| IP doesn't change | Tor reused the same circuit | Normal — will change next round |
| Tor fails to connect (3 attempts) | Network issue or Tor blocked | Check internet connection, try again |
| `systemctl: command not found` | Running in a minimal container | Use a full Kali install, not a Docker container |

---

## Verify Tor is Working Independently

Before running the script, you can test Tor manually:

```bash
# This should return a different IP than your real one
curl --socks5-hostname 127.0.0.1:9050 https://api.ipify.org

# Compare with your real IP
curl https://api.ipify.org
```

If both commands return different IPs — Tor is working correctly.

---

## Project Structure

```
ip-blinker/
│
├── ip_blinker.sh     # Main script
└── README.md         # This file
```

---

## Important Notes

- The script only rotates the **Tor exit node IP** — not your real IP
- Your real IP is never exposed to `api.ipify.org` — all requests go through Tor
- Tor exit nodes are chosen randomly from the Tor network's relay pool
- Sometimes the same exit node is reused — this is normal Tor behavior
- IP changes are not instant — Tor needs time to negotiate a new circuit

---

## License

This project is released under the **GNU General Public License v2.0 (GPLv2)**.

You are free to use, modify, and distribute this software under the terms of GPLv2.  
Full license: https://www.gnu.org/licenses/old-licenses/gpl-2.0.html

---

## Disclaimer

> This tool is developed strictly for **educational and research purposes only.**
>
> Using Tor and rotating IPs is legal in most countries for privacy protection  
> and research. However, using this tool to conduct unauthorized access,  
> bypass security controls on systems you do not own, or engage in any  
> illegal activity is **strictly prohibited.**
>
> The author is **NOT responsible** for any misuse or legal consequences  
> resulting from the use of this tool.
>
> Always comply with your local laws and the terms of service of any  
> network or system you interact with.

---

## Author

**Sahebrao Rahire**  
GitHub: [github.com/Rahires](https://github.com/Rahires)  
Year: 2026

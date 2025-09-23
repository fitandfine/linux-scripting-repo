#!/usr/bin/env bash
# dns_tracker.sh
# --------------------
# Purpose:
#   Real-time DNS query monitoring on Linux.
#   Captures all DNS queries on UDP port 53 and displays them live with timestamps.
#   Repeated domains are highlighted in red.
#   Optionally saves captured queries to a user-specified file.
#
# Notes:
#   - Works only for unencrypted DNS (UDP 53). DoH/VPN queries will NOT appear.
#   - Requires sudo/root privileges.
#   - Requires tcpdump installed: sudo apt install tcpdump
#   - GitHub-friendly and educational.
#
# Features:
#   - Live display of DNS queries
#   - Timestamped queries
#   - Repeated domains highlighted in red
#   - Optional file output
#   - Color-coded output
#
# Usage:
#   sudo ./dns_tracker.sh
#   Press Ctrl+C to stop.
#
# Running on Startup:
#   1. Save this script, e.g., /usr/local/bin/dns_tracker.sh
#   2. Make it executable:
#        sudo chmod +x /usr/local/bin/dns_tracker.sh
#   3. Create a systemd service:
#        sudo nano /etc/systemd/system/dns_tracker.service
#        Paste:
#        [Unit]
#        Description=Live DNS Tracker
#        After=network.target
#
#        [Service]
#        Type=simple
#        ExecStart=/usr/local/bin/dns_tracker.sh /home/YOUR_USERNAME/dns_log.txt
#        Restart=always
#        User=root
#
#        [Install]
#        WantedBy=multi-user.target
#
#   4. Enable and start:
#        sudo systemctl daemon-reload
#        sudo systemctl enable dns_tracker.service
#        sudo systemctl start dns_tracker.service
#
#   5. All live DNS queries will be logged to the specified file.

set -euo pipefail

# ---------------------------
# Root check
# ---------------------------
if [[ $EUID -ne 0 ]]; then
  echo "⚠️ Must run as sudo/root."
  echo "Example: sudo $0"
  exit 1
fi

# ---------------------------
# Check tcpdump
# ---------------------------
if ! command -v tcpdump &>/dev/null; then
  echo "❌ tcpdump not found. Install it with: sudo apt install tcpdump"
  exit 1
fi

# ---------------------------
# Optional file output
# Accept either argument or ask interactively
# ---------------------------
SAVE_FILE="${1:-""}"

if [[ -z "$SAVE_FILE" ]]; then
  read -rp "Do you want to save DNS queries to a file? [y/N]: " save_choice
  if [[ "$save_choice" =~ ^[Yy]$ ]]; then
    read -rp "Enter full path for output file (e.g., ~/dns_log.txt): " raw_path
    # Expand ~ to home directory of the original user if present
    if [[ -n "$SUDO_USER" ]]; then
      ORIG_HOME=$(eval echo "~$SUDO_USER")
    else
      ORIG_HOME="$HOME"
    fi
    SAVE_FILE="${raw_path/#\~/$ORIG_HOME}"
  fi
fi

# Ensure directory exists and file is touchable
if [[ -n "$SAVE_FILE" ]]; then
  mkdir -p "$(dirname "$SAVE_FILE")"
  touch "$SAVE_FILE" || { echo "❌ Cannot create file $SAVE_FILE"; exit 1; }
  echo "✅ DNS queries will be saved to $SAVE_FILE"
fi

# ---------------------------
# Color settings
# ---------------------------
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# ---------------------------
# Associative array to track repeated domains
# ---------------------------
declare -A domain_count

# ---------------------------
# Function: Monitor live DNS queries
# ---------------------------
monitor_dns() {
  echo -e "${GREEN}🌐 Starting live DNS query monitoring. Press Ctrl+C to stop.${NC}"

  sudo tcpdump -l -nn udp port 53 2>/dev/null \
    | while read -r line; do
        timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        for word in $line; do
          # Basic domain filter
          if [[ "$word" =~ \. ]]; then
            domain="$word"
            count=${domain_count["$domain"]:-0}
            count=$((count + 1))
            domain_count["$domain"]=$count

            # Red for repeated domains, yellow for first occurrence
            color=$YELLOW
            [[ $count -gt 1 ]] && color=$RED

            # Print live output
            echo -e "${timestamp} ${color}${domain}${NC}"

            # Append to file if specified
            [[ -n "$SAVE_FILE" ]] && echo "${timestamp} ${domain}" >> "$SAVE_FILE"
          fi
        done
      done
}

# ---------------------------
# Main Execution
# ---------------------------
monitor_dns

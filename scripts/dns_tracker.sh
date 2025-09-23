#!/usr/bin/env bash
# dns_tracker.sh
# --------------------
# Purpose:
#   Real-time DNS query monitoring on Linux.
#   Captures all DNS queries on UDP port 53 and displays them live with timestamps.
#   Repeated domains are highlighted in color.
#   Optionally saves captured queries to a user-specified file.
#
# Notes:
#   - Works only for unencrypted DNS (UDP 53). DoH/VPN queries will NOT appear.
#   - Requires sudo/root privileges.
#   - Requires tcpdump installed: sudo apt install tcpdump
#   - Easy-to-use, GitHub-friendly, suitable for educational purposes.
#
# Features:
#   - Live display of DNS queries.
#   - Highlights repeated domains in red.
#   - Shows timestamp for each query.
#   - Optional file output.
#   - Color-coded output for better readability.
#
# Usage:
#   sudo ./dns_tracker.sh
#   Press Ctrl+C to stop.
#
# Running on Startup:
#   1. Save this script, e.g., /usr/local/bin/dns_tracker.sh
#   2. Make it executable: sudo chmod +x /usr/local/bin/dns_tracker.sh
#   3. Create a systemd service: sudo nano /etc/systemd/system/dns_tracker.service
#      [Unit]
#      Description=Live DNS Tracker
#
#      [Service]
#      ExecStart=/usr/local/bin/dns_tracker.sh
#      Restart=always
#      User=root
#
#      [Install]
#      WantedBy=multi-user.target
#
#   4. Enable and start:
#      sudo systemctl daemon-reload
#      sudo systemctl enable dns_tracker.service
#      sudo systemctl start dns_tracker.service
#
#   5. All live DNS queries will be logged in the specified file if chosen.
set -euo pipefail

# ---------------------------
# Root check
# ---------------------------
if [[ $EUID -ne 0 ]]; then
  echo "⚠️  Must run as sudo/root."
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
# Ask user for optional file output
# ---------------------------
SAVE_FILE=""
read -rp "Do you want to save DNS queries to a file? [y/N]: " save_choice
if [[ "$save_choice" =~ ^[Yy]$ ]]; then
  read -rp "Enter full path for output file (e.g., ~/dns_log.txt): " raw_path
  # Expand ~ to home directory
  SAVE_FILE="${raw_path/#\~/$HOME}"
  # Ensure the directory exists
  mkdir -p "$(dirname "$SAVE_FILE")"
  touch "$SAVE_FILE"
  echo "✅ DNS queries will be saved to $SAVE_FILE"
fi

# ---------------------------
# Color settings
# ---------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
          if [[ "$word" =~ \. ]]; then
            domain="$word"

            # Initialize count safely
            count=${domain_count["$domain"]:-0}
            count=$((count + 1))
            domain_count["$domain"]=$count

            # Choose color: red for repeated domains, yellow for first time
            if [[ $count -gt 1 ]]; then
              color=$RED
            else
              color=$YELLOW
            fi

            # Print with timestamp and color
            echo -e "${timestamp} ${color}${domain}${NC}"

            # Save to file if specified
            if [[ -n "$SAVE_FILE" ]]; then
              echo "${timestamp} ${domain}" >> "$SAVE_FILE"
            fi
          fi
        done
      done
}

# ---------------------------
# Main execution
# ---------------------------
monitor_dns
#!/usr/bin/env bash
# dns_tracker.sh
# --------------------
# Purpose:
#   Monitor and analyze local DNS queries on Linux.
#   Displays recent DNS queries, counts repeated queries, and allows real-time monitoring.
#
# Important Note:
#   This script cannot track encrypted DNS queries (DoH) or VPN traffic.
#   Incognito/private browser queries may not appear if encrypted.
#
# Usage:
#   ./dns_query_tracker.sh [OPTIONS]
# Options:
#   -h | --help       Show help
#   -f | --follow     Continuously follow new DNS queries
#   -n | --number N   Show last N queries (default: 50)
#
# Requirements:
#   - Must have permission to read system logs (usually sudo)
#   - Works with systemd-resolved logs or syslog

set -euo pipefail

# ---------------------------
# Default Settings
# ---------------------------
FOLLOW=0
NUM=50

# ---------------------------
# Function: Show Help
# ---------------------------
show_help() {
  cat << EOF
Usage: $0 [OPTIONS]

Options:
  -h, --help        Show this help message
  -f, --follow      Continuously follow new DNS queries
  -n, --number N    Show last N queries (default: 50)

Examples:
  $0               # Show last 50 DNS queries
  $0 --follow      # Follow new queries in real-time
  $0 -n 100        # Show last 100 queries
EOF
}

# ---------------------------
# Parse Arguments
# ---------------------------
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) show_help; exit 0 ;;
    -f|--follow) FOLLOW=1; shift ;;
    -n|--number)
      NUM="${2:-50}"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# ---------------------------
# Determine Log Source
# ---------------------------
DNS_LOG_SOURCE="systemd-resolved"

# ---------------------------
# Function: Fetch DNS Queries
# ---------------------------
fetch_dns_logs() {
  local follow="$1"
  local num="$2"

  echo "Fetching DNS queries from local logs..."

  if [[ "$DNS_LOG_SOURCE" == "systemd-resolved" ]]; then
    if ! command -v journalctl &>/dev/null; then
      echo "journalctl not found. Install systemd or use syslog."
      exit 1
    fi

    if [[ "$follow" -eq 1 ]]; then
      # Follow DNS queries in real-time
      sudo journalctl -u systemd-resolved -f | grep --line-buffered "DNS query" | awk '{print $0}'
    else
      # Show last N queries
      sudo journalctl -u systemd-resolved | grep "DNS query" | tail -n "$num"
    fi
  else
    # Fallback to syslog if systemd-resolved unavailable
    SYSLOG="/var/log/syslog"
    if [[ ! -f "$SYSLOG" ]]; then
      echo "Syslog not found at $SYSLOG"
      exit 1
    fi

    if [[ "$follow" -eq 1 ]]; then
      sudo tail -f "$SYSLOG" | grep --line-buffered "named\|DNS"
    else
      sudo grep "named\|DNS" "$SYSLOG" | tail -n "$num"
    fi
  fi
}

# ---------------------------
# Function: Summarize DNS Queries
# ---------------------------
summarize_queries() {
  local logs="$1"

  echo -e "\n📊 DNS Query Summary:"
  echo "------------------------"

  # Extract domain names from logs using awk/grep
  # Works for systemd-resolved log format: "DNS query ... <domain>"
  echo "$logs" | awk '{for(i=1;i<=NF;i++) if($i ~ /\./) print $i}' \
    | sort \
    | uniq -c \
    | sort -nr \
    | awk '{printf "%-40s %5s\n", $2, $1}'

  echo "------------------------"
  echo "Top repeated domains are listed above."
}

# ---------------------------
# Main Execution
# ---------------------------
if [[ "$FOLLOW" -eq 1 ]]; then
  echo "Following DNS queries in real-time. Press Ctrl+C to stop."
  fetch_dns_logs 1 0
else
  logs=$(fetch_dns_logs 0 "$NUM")
  echo "$logs"
  summarize_queries "$logs"
fi

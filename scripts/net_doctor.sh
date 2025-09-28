#!/usr/bin/env bash
# net_doctor.sh
#
# A beginner-friendly Linux script to diagnose common network issues.
# Useful for ISPs, sysadmins, and learners.
#
# Features:
#   * Check internet connectivity
#   * DNS resolution test
#   * Ping test (latency check)
#   * Trace route test
#   * Logging with timestamps
#   * Interactive and beginner-friendly
#
# Usage:
#   ./net_doctor.sh                  # Run interactive menu
#   ./net_doctor.sh --check          # Run all checks automatically
#   ./net_doctor.sh --help           # Show help
#
# Author: Anup Chapain

LOGFILE="$HOME/net_doctor.log"

# ------------------------------------------------------------
# Function: show_help
# Display usage instructions
# ------------------------------------------------------------
show_help() {
    cat <<EOF
Network Doctor (net_doctor.sh)
------------------------------
A simple tool to diagnose basic network problems.

USAGE:
  ./net_doctor.sh              # Run interactive menu
  ./net_doctor.sh --check      # Run all tests automatically
  ./net_doctor.sh --help       # Show this help message

FEATURES:
  * Check internet connectivity
  * DNS resolution test
  * Ping test (latency check)
  * Trace route to a target host
  * Logs saved to: $LOGFILE
EOF
}

# ------------------------------------------------------------
# Function: log_msg
# Append a timestamped message to log file
# ------------------------------------------------------------
log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

# ------------------------------------------------------------
# Function: check_internet
# Test if we can reach the internet
# ------------------------------------------------------------
check_internet() {
    log_msg "🌐 Checking internet connectivity..."
    if ping -c 2 8.8.8.8 &>/dev/null; then
        log_msg "✔ Internet is reachable (Google DNS responded)."
    else
        log_msg "❌ Cannot reach the internet (ping to 8.8.8.8 failed)."
    fi
}

# ------------------------------------------------------------
# Function: dns_check
# Resolve a domain using dig or nslookup
# ------------------------------------------------------------
dns_check() {
    DOMAIN="google.com"
    log_msg "🔍 Checking DNS resolution for $DOMAIN..."
    if command -v dig &>/dev/null; then
        dig +short "$DOMAIN" | tee -a "$LOGFILE"
    elif command -v nslookup &>/dev/null; then
        nslookup "$DOMAIN" | tee -a "$LOGFILE"
    else
        log_msg "⚠ No DNS tools (dig/nslookup) installed."
    fi
}

# ------------------------------------------------------------
# Function: ping_test
# Ping a domain to measure latency
# ------------------------------------------------------------
ping_test() {
    TARGET="google.com"
    log_msg "📡 Pinging $TARGET..."
    ping -c 4 "$TARGET" | tee -a "$LOGFILE"
}

# ------------------------------------------------------------
# Function: trace_route
# Trace network path to target
# ------------------------------------------------------------
trace_route() {
    TARGET="google.com"
    log_msg "🛣️ Tracing route to $TARGET..."
    if command -v traceroute &>/dev/null; then
        traceroute "$TARGET" | tee -a "$LOGFILE"
    elif command -v tracepath &>/dev/null; then
        tracepath "$TARGET" | tee -a "$LOGFILE"
    else
        log_msg "⚠ traceroute/tracepath not available."
    fi
}

# ------------------------------------------------------------
# Function: run_all
# Run all checks in sequence
# ------------------------------------------------------------
run_all() {
    check_internet
    dns_check
    ping_test
    trace_route
    log_msg "✅ Network checks completed. Results saved in $LOGFILE"
}

# ------------------------------------------------------------
# Function: interactive_menu
# Offer interactive choices for beginners
# ------------------------------------------------------------
interactive_menu() {
    while true; do
        echo "============================================================"
        echo "🩺 Network Doctor Menu"
        echo "============================================================"
        echo "1) Check internet connectivity"
        echo "2) Test DNS resolution"
        echo "3) Run ping test"
        echo "4) Trace route"
        echo "5) Run all checks"
        echo "q) Quit"
        read -rp "👉 Choose an option: " choice

        case "$choice" in
            1) check_internet ;;
            2) dns_check ;;
            3) ping_test ;;
            4) trace_route ;;
            5) run_all ;;
            q|Q) exit 0 ;;
            *) echo "❌ Invalid choice, try again." ;;
        esac
    done
}

# ------------------------------------------------------------
# Main Program Logic
# ------------------------------------------------------------
case "$1" in
    --help|-h)
        show_help
        ;;
    --check)
        run_all
        ;;
    "")
        interactive_menu
        ;;
    *)
        echo "❌ Invalid option: $1"
        echo "Use --help for usage instructions."
        exit 1
        ;;
esac

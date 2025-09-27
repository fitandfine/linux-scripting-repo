#!/usr/bin/env bash
# net_monitor.sh
#
# Production-grade Network Monitoring Tool
#
# Features:
#   * Real-time monitoring of network usage
#   * Logs output to both terminal and ~/net_monitor.log
#   * Supports "nethogs" (per-process stats) and "ss" (socket stats)
#   * Lets user choose which tool to use (if both available)
#   * Prompts to install "nethogs" if missing
#   * Report generation from logs with meaningful analysis
#
# Usage:
#   ./net_monitor.sh               # Run interactive monitoring
#   ./net_monitor.sh --report      # Generate usage report from logs
#   ./net_monitor.sh -h | --help   # Show help menu
#
# Author: Anup Chapain

LOGFILE=~/net_monitor.log

# ------------------------------------------------------------
# Function: show_help
# Display usage instructions
# ------------------------------------------------------------
show_help() {
    cat <<EOF
Network Monitor Tool (net_monitor.sh)
-------------------------------------
This script monitors real-time network usage, logs activity,
and generates comprehensive reports.

USAGE:
  ./net_monitor.sh
  ./net_monitor.sh --report
  ./net_monitor.sh -h | --help

OPTIONS:
  --report    Generate a usage report from the log file
  -h, --help  Show this help message

FEATURES:
  * Real-time monitoring of bandwidth
  * Logs activity to both terminal and $LOGFILE
  * Choose between "nethogs" (per-process) or "ss" (socket-level)
  * Prompts to install "nethogs" if missing
  * Falls back to "ss" if you prefer not to install
EOF
}

# ------------------------------------------------------------
# Function: monitor_network
# Interactive selection of monitoring tool
# ------------------------------------------------------------
monitor_network() {
    mkdir -p "$(dirname "$LOGFILE")"
    touch "$LOGFILE"

    echo "============================================================"
    echo "📡 Starting Real-Time Network Monitor (press Ctrl+C to stop)"
    echo "============================================================"
    echo "Logging activity to $LOGFILE"
    echo

    # Tool availability check
    HAS_NETHOGS=false
    HAS_SS=false
    command -v nethogs &>/dev/null && HAS_NETHOGS=true
    command -v ss &>/dev/null && HAS_SS=true

    echo "Select monitoring tool:"
    echo "1) nethogs (per-process bandwidth monitoring)"
    echo "2) ss (socket-level connection monitoring)"
    read -rp "Choice [1/2]: " choice

    case "$choice" in
        1)
            if $HAS_NETHOGS; then
                run_nethogs
            else
                echo "⚠ nethogs is not installed."
                read -rp "Do you want to install it now? (y/n): " ans
                if [[ "$ans" == "y" ]]; then
                    install_nethogs
                    run_nethogs
                else
                    echo "⚠ Falling back to ss-based monitoring..."
                    use_ss
                fi
            fi
            ;;
        2)
            if $HAS_SS; then
                use_ss
            else
                echo "❌ 'ss' command not available. Exiting."
                exit 1
            fi
            ;;
        *)
            echo "❌ Invalid choice. Exiting."
            exit 1
            ;;
    esac
}

# ------------------------------------------------------------
# Function: run_nethogs
# Run nethogs with logging and timestamps
# ------------------------------------------------------------
run_nethogs() {
    echo "✔ Using nethogs for per-process monitoring"
    echo "------------------------------------------------------------"
    # Prefix each line with timestamp
    sudo nethogs -t 2>&1 | while read -r line; do
        echo "TIMESTAMP: $(date) | $line" | tee -a "$LOGFILE"
    done
}

# ------------------------------------------------------------
# Function: install_nethogs
# Detect package manager and install nethogs
# ------------------------------------------------------------
install_nethogs() {
    if command -v apt &>/dev/null; then
        echo "Installing nethogs with apt..."
        sudo apt update && sudo apt install -y nethogs
    elif command -v yum &>/dev/null; then
        echo "Installing nethogs with yum..."
        sudo yum install -y nethogs
    else
        echo "❌ Unknown package manager. Please install nethogs manually."
    fi
}

# ------------------------------------------------------------
# Function: use_ss
# Fallback monitoring using ss
# ------------------------------------------------------------
use_ss() {
    echo "✔ Using ss for socket monitoring"
    echo "------------------------------------------------------------"
    while true; do
        echo "TIMESTAMP: $(date)" | tee -a "$LOGFILE"
        ss -tunap 2>&1 | tee -a "$LOGFILE"
        sleep 5
    done
}

# ------------------------------------------------------------
# Function: generate_report
# Analyze the log file for meaningful trends
# ------------------------------------------------------------
generate_report() {
    if [[ ! -f "$LOGFILE" ]]; then
        echo "❌ No log file found at $LOGFILE"
        echo "Run the script normally first to generate logs."
        exit 1
    fi

    echo "============================================================"
    echo "📊 Network Usage Report"
    echo "============================================================"

    # ----- Nethogs Logs -----
    if grep -q "KB/sec" "$LOGFILE"; then
        echo "🔝 Top 10 Processes by Total Bandwidth (nethogs logs):"
        grep "KB/sec" "$LOGFILE" \
            | awk '{key=$2" "$3; kb=$NF; total[key]+=kb} END {for (i in total) printf "%10.2f KB\t%s\n", total[i], i}' \
            | sort -nr | head -10
        echo

        echo "👤 Top 5 Users by Bandwidth:"
        grep "KB/sec" "$LOGFILE" \
            | awk '{user=$1; kb=$NF; total[user]+=kb} END {for (i in total) printf "%10.2f KB\t%s\n", total[i], i}' \
            | sort -nr | head -5
        echo

        echo "🕒 Peak Bandwidth Timeline:"
        grep "KB/sec" "$LOGFILE" \
            | awk '{print $1, $2, $3, $NF}' \
            | sort -k4 -nr | head -10
        echo
    fi

    # ----- SS Logs -----
    if grep -q "ESTAB\|LISTEN" "$LOGFILE"; then
        echo "🌐 Top 10 Remote IPs (ss logs):"
        awk '/ESTAB|LISTEN/ {split($5,a,":"); if(a[1]!="") print a[1]}' "$LOGFILE" \
            | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' \
            | sort | uniq -c | sort -nr | head -10
        echo

        echo "📦 Protocol Usage (tcp/udp):"
        awk '/tcp|udp/ {print $1}' "$LOGFILE" \
            | sort | uniq -c | sort -nr
        echo
    fi

    # ----- Monitoring Sessions Timeline -----
    echo "🕒 Monitoring Sessions Timeline:"
    grep -F -- "TIMESTAMP:" "$LOGFILE" | sed 's/TIMESTAMP: //'
    echo "============================================================"
    echo "✔ Report generated from logs at $LOGFILE"
}

# ------------------------------------------------------------
# Main Program Logic
# ------------------------------------------------------------
case "$1" in
    -h|--help)
        show_help
        ;;
    --report)
        generate_report
        ;;
    "")
        monitor_network
        ;;
    *)
        echo "❌ Invalid option: $1"
        echo "Use --help to see usage."
        exit 1
        ;;
esac

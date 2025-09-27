#!/usr/bin/env bash
# sys_diagnose.sh
# for line by line explanation, see sys_diagnose.md inside the notes directory
# Comprehensive Linux service diagnostic tool with numeric indexing.
# Lists all services on systemd-based systems and allows interactive
# management (status, start, stop, restart, enable/disable, logs).
#
# Usage:
#   ./sys_diagnose.sh
#   ./sys_diagnose.sh -h | --help
#
# Written for DevOps interview prep (e.g., SiteHost.nz)

# ------------------------------------------------------------
# Function: show_help
# Displays the help/usage message
# ------------------------------------------------------------
show_help() {
    cat <<EOF
System Diagnostic Tool (sys_diagnose.sh)
----------------------------------------
This script lists ALL services installed on your Linux system
(using systemctl) and allows interactive troubleshooting.

USAGE:
  ./sys_diagnose.sh
  ./sys_diagnose.sh -h | --help

FEATURES:
  * Lists all systemd services with numeric indexes
  * Shows if services are enabled/disabled and running/stopped
  * Lets you pick a service by number to:
      - View detailed status
      - Start/Stop/Restart
      - Enable/Disable at boot
      - View logs with journalctl
EOF
}

# ------------------------------------------------------------
# Function: list_services
# Collects all services and stores in an array
# ------------------------------------------------------------
list_services() {
    echo "============================================================"
    echo "📋 Installed Services on this System"
    echo "============================================================"

    # Initialize array
    SERVICES=()

    # Extract services into array
    while IFS= read -r line; do
        service=$(echo "$line" | awk '{print $1}')
        state=$(echo "$line" | awk '{print $2}')
        active=$(systemctl is-active "$service" 2>/dev/null)
        SERVICES+=("$service|$state|$active")
    done < <(systemctl list-unit-files --type=service --no-pager | awk 'NR>1 && $1 ~ /\.service$/ {print $1, $2}' | sort)

    # Print indexed list
    for i in "${!SERVICES[@]}"; do
        svc=$(echo "${SERVICES[$i]}" | cut -d'|' -f1)
        state=$(echo "${SERVICES[$i]}" | cut -d'|' -f2)
        active=$(echo "${SERVICES[$i]}" | cut -d'|' -f3)
        printf "%3d) %-40s %-12s %-12s\n" $((i+1)) "$svc" "$state" "$active"
    done
    echo
}

# ------------------------------------------------------------
# Function: interactive_menu
# Lets user select service by number and take actions
# ------------------------------------------------------------
interactive_menu() {
    while true; do
        echo "============================================================"
        echo "⚙️  Interactive Service Management"
        echo "============================================================"
        echo "Choose a service by NUMBER (from the list above), or 'q' to quit."
        read -rp "Service number: " choice

        [[ "$choice" == "q" ]] && break

        # Validate numeric input
        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            echo "❌ Invalid input. Please enter a number."
            continue
        fi

        index=$((choice-1))
        if [[ $index -lt 0 || $index -ge ${#SERVICES[@]} ]]; then
            echo "❌ Invalid number. Please pick from the list."
            continue
        fi

        # Extract service name
        svc=$(echo "${SERVICES[$index]}" | cut -d'|' -f1)

        echo "What do you want to do with $svc?"
        echo "1) View status"
        echo "2) Start service"
        echo "3) Stop service"
        echo "4) Restart service"
        echo "5) Enable on boot"
        echo "6) Disable on boot"
        echo "7) Show logs (journalctl)"
        echo "q) Back to service list"
        read -rp "Choose an option: " action

        case "$action" in
            1) systemctl status "$svc" --no-pager ;;
            2) sudo systemctl start "$svc" && echo "✔ Started $svc" ;;
            3) sudo systemctl stop "$svc" && echo "✔ Stopped $svc" ;;
            4) sudo systemctl restart "$svc" && echo "✔ Restarted $svc" ;;
            5) sudo systemctl enable "$svc" && echo "✔ Enabled $svc on boot" ;;
            6) sudo systemctl disable "$svc" && echo "✔ Disabled $svc on boot" ;;
            7) sudo journalctl -u "$svc" -n 20 --no-pager ;;
            q) continue ;;
            *) echo "❌ Invalid option." ;;
        esac
    done
}

# ------------------------------------------------------------
# Main Program Logic
# ------------------------------------------------------------
case "$1" in
    -h|--help)
        show_help
        ;;
    "")
        list_services
        interactive_menu
        ;;
    *)
        echo "Invalid option: $1"
        echo "Use --help to see usage."
        exit 1
        ;;
esac

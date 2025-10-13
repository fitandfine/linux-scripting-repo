#!/usr/bin/env bash
# port_inspector.sh
# A Linux port inspector and management tool with a menu-driven interface.
#
# Features:
#   - Lists all active TCP/UDP ports with process name, PID, and user.
#   - Provides a menu for selecting which port to free.
#   - Detects systemd-managed services (like apache2, nginx) and suggests stopping via systemctl.
#   - Protects critical system processes (like sshd, systemd) from accidental killing.
#   - Fully commented for maintainability and DevOps interviews.

# Author: Anup Chapain
# ------------------------------------------------------------
# Show help
# ------------------------------------------------------------
show_help() {
    cat <<EOF
Port Inspector Tool
-------------------
This script helps you identify which ports are in use on your Linux system
and allows you to free them interactively.

USAGE:
  ./port_inspector.sh            # List ports and show menu
  ./port_inspector.sh --help     # Show help

EXAMPLES:
  ./port_inspector.sh
EOF
}

# ------------------------------------------------------------
# Function: check if a process is a critical system service
# ------------------------------------------------------------
is_critical_service() {
    local process_name="$1"
    local critical=("sshd" "systemd" "init" "cron" "dbus-daemon" \
                    "NetworkManager" "firewalld" "systemd-resolve")

    for svc in "${critical[@]}"; do
        if [[ "$process_name" == *"$svc"* ]]; then
            return 0  # yes, critical
        fi
    done
    return 1  # safe
}

# ------------------------------------------------------------
# Function: list active ports with lsof (preferred)
# ------------------------------------------------------------
list_ports() {
    # lsof gives process name, PID, user, and port details
    sudo lsof -i -P -n | grep -E "LISTEN|UDP" | \
    awk 'NR>0 {printf "%-5s %-10s %-8s %-8s %-25s\n", NR, $1, $2, $3, $9}' \
    | column -t
    # Columns:
    # INDEX PROCESS PID USER ADDRESS:PORT
}

# ------------------------------------------------------------
# Function: build a list of active ports (for menu)
# ------------------------------------------------------------
get_port_list() {
    sudo lsof -i -P -n | grep -E "LISTEN|UDP" | \
    awk '{print $1, $2, $3, $9}'
}

# ------------------------------------------------------------
# Function: free a port safely
# ------------------------------------------------------------
free_port() {
    local process_name="$1"
    local pid="$2"
    local user="$3"
    local port="$4"

    echo "============================================================"
    echo "Selected process details:"
    echo "  Service Name : $process_name"
    echo "  PID          : $pid"
    echo "  User         : $user"
    echo "  Port         : $port"
    echo "============================================================"

    # Step 1: Check if process is critical
    if is_critical_service "$process_name"; then
        echo "⚠️ WARNING: '$process_name' is a CRITICAL system service."
        echo "   Killing it may crash your server or disconnect SSH."
        read -p "Are you ABSOLUTELY sure you want to kill it? (type 'yes' to confirm): " ans
        [[ "$ans" != "yes" ]] && { echo "❌ Operation cancelled."; return; }
    fi

    # Step 2: If the process is systemd-managed (e.g., apache2, nginx, mysql)
    if systemctl list-unit-files | grep -q "$process_name"; then
        echo "⚠️ Detected '$process_name' is managed by systemd."
        echo "   Killing it directly will only restart it!"
        read -p "Do you want to stop it properly via systemctl instead? (y/n): " choice
        if [[ "$choice" == "y" ]]; then
            sudo systemctl stop "$process_name"
            echo "✅ Stopped $process_name service using systemctl."
            return
        fi
    fi

    # Step 3: Kill process safely
    read -p "Do you want to kill PID $pid ($process_name)? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        if [[ "$user" == "root" && $EUID -ne 0 ]]; then
            echo "⚠️ Process is owned by root. Using sudo to kill..."
            sudo kill -9 "$pid"
        else
            kill -9 "$pid"
        fi

        if [[ $? -eq 0 ]]; then
            echo "✅ Process $pid ($process_name) killed. Port $port is now free."
        else
            echo "❌ Failed to kill process $pid."
        fi
    else
        echo "✘ Operation cancelled. Port $port remains in use."
    fi
}

# ------------------------------------------------------------
# Menu-driven interface
# ------------------------------------------------------------
menu_mode() {
    echo "============================================================"
    echo "Active Ports and Associated Services"
    echo "============================================================"
    echo "INDEX PROCESS    PID      USER     PORT"
    echo "------------------------------------------------------------"

    # List ports with index numbers
    port_list=($(get_port_list)) # array of fields: process PID user port
    i=1
    while read -r line; do
        echo "$i $line"
        i=$((i+1))
    done <<< "$(get_port_list)"

    echo "------------------------------------------------------------"
    read -p "Enter the INDEX of the port you want to free (or 'q' to quit): " choice

    if [[ "$choice" == "q" ]]; then
        echo "Exiting."
        exit 0
    fi

    # Validate choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid choice."
        exit 1
    fi

    # Extract fields for selected index
    selected_line=$(get_port_list | sed -n "${choice}p")
    process_name=$(echo "$selected_line" | awk '{print $1}')
    pid=$(echo "$selected_line" | awk '{print $2}')
    user=$(echo "$selected_line" | awk '{print $3}')
    port=$(echo "$selected_line" | awk '{print $4}')

    free_port "$process_name" "$pid" "$user" "$port"
}

# ------------------------------------------------------------
# Main logic
# ------------------------------------------------------------
case "$1" in
    -h|--help)
        show_help
        ;;
    *)
        menu_mode
        ;;
esac

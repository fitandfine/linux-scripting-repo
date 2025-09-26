#!/usr/bin/env bash
# port_inspector.sh
# A Linux port inspector and management tool with safe-kill options
#
# Usage:
#   ./port_inspector.sh                # List all used ports with services
#   ./port_inspector.sh --free <port>  # Free a specific port interactively
#   ./port_inspector.sh -h | --help    # Show help
#
# Features:
#   - Lists all TCP/UDP ports in use with PROCESS NAME + PID + USER.
#   - Lets you kill the process holding a port, but warns for critical services.
#   - Automatically asks for sudo if needed.
#   - User-friendly output with warnings and confirmations.

# ------------------------------------------------------------
# Show help function
# ------------------------------------------------------------
show_help() {
    cat <<EOF
Port Inspector Tool
-------------------
This script helps you identify which ports are in use on your Linux system
and allows you to free them interactively if required.

USAGE:
  ./port_inspector.sh
  ./port_inspector.sh --free <port>
  ./port_inspector.sh --help | -h

OPTIONS:
  --free <port>   Free the given port (by killing the process using it).
  --h, --help      Show this help message.

EXAMPLES:
  ./port_inspector.sh
  ./port_inspector.sh --free 8080
EOF
}

# ------------------------------------------------------------
# List ports and their services (with process name + PID + user)
# ------------------------------------------------------------
list_ports() {
    echo "============================================================"
    echo "Active Ports and Associated Services"
    echo "============================================================"

    # Use lsof for better process resolution (shows PID + user + command)
    if command -v lsof >/dev/null 2>&1; then
        sudo lsof -i -P -n | grep -E "LISTEN|UDP" | awk '{printf "%-8s %-8s %-8s %-20s %-20s %-10s\n", $1, $2, $3, $9, $8, $1}'
        # Output columns:
        # COMMAND   PID   USER   ADDRESS:PORT   NODE   NAME
    elif command -v ss >/dev/null 2>&1; then
        sudo ss -tulpn
    else
        echo "❌ Neither 'lsof' nor 'ss' found. Please install one of them."
        exit 1
    fi
}

# ------------------------------------------------------------
# Define critical system processes that are unsafe to kill
# ------------------------------------------------------------
is_critical_service() {
    local process_name="$1"
    local critical=("sshd" "systemd" "init" "cron" "dbus-daemon" \
                    "NetworkManager" "firewalld" "nginx" "apache2" "mysql" "postgres")

    for svc in "${critical[@]}"; do
        if [[ "$process_name" == *"$svc"* ]]; then
            return 0
        fi
    done
    return 1
}

# ------------------------------------------------------------
# Free a port by killing its process safely
# ------------------------------------------------------------
free_port() {
    PORT=$1
    if [[ -z "$PORT" ]]; then
        echo "❌ Error: No port specified."
        exit 1
    fi

    # Find process info using lsof
    PROCESS_INFO=$(sudo lsof -i :$PORT -sTCP:LISTEN -n -P | awk 'NR==2 {print $1, $2, $3}')
    if [[ -z "$PROCESS_INFO" ]]; then
        echo "⚠️ No process found using port $PORT."
        exit 1
    fi

    PROCESS_NAME=$(echo "$PROCESS_INFO" | awk '{print $1}')
    PROCESS_PID=$(echo "$PROCESS_INFO" | awk '{print $2}')
    PROCESS_USER=$(echo "$PROCESS_INFO" | awk '{print $3}')

    echo "============================================================"
    echo "Process using port $PORT:"
    echo "  Service Name : $PROCESS_NAME"
    echo "  PID          : $PROCESS_PID"
    echo "  User         : $PROCESS_USER"
    echo "============================================================"

    # Safety check for critical processes
    if is_critical_service "$PROCESS_NAME"; then
        echo "⚠️ WARNING: '$PROCESS_NAME' (PID: $PROCESS_PID) is a CRITICAL system service."
        echo "   Killing it may crash your server or disconnect SSH."
        read -p "Are you ABSOLUTELY sure you want to kill it? (type 'yes' to confirm): " ans
        [[ "$ans" != "yes" ]] && { echo "❌ Operation cancelled."; exit 1; }
    fi

    # Elevate privileges if required
    if [[ "$PROCESS_USER" == "root" && $EUID -ne 0 ]]; then
        echo "⚠️ Process is owned by root. Using sudo to kill..."
        SUDO="sudo"
    else
        SUDO=""
    fi

    # Final confirmation
    read -p "Do you want to kill PID $PROCESS_PID ($PROCESS_NAME)? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        $SUDO kill -9 "$PROCESS_PID"
        if [[ $? -eq 0 ]]; then
            echo "✅ Process $PROCESS_PID ($PROCESS_NAME) killed. Port $PORT is now free."
        else
            echo "❌ Failed to kill process $PROCESS_PID."
        fi
    else
        echo "✘ Operation cancelled. Port $PORT remains in use."
    fi
}

# ------------------------------------------------------------
# Main logic
# ------------------------------------------------------------
case "$1" in
    --h|--help)
        show_help
        ;;
    --free)
        free_port "$2"
        ;;
    "")
        list_ports
        ;;
    *)
        echo "❌ Invalid option: $1"
        echo "Use --help to see usage."
        exit 1
        ;;
esac

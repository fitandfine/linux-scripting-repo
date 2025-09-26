#!/usr/bin/env bash
# port_inspector.sh
# A Linux port inspector and management tool
#
# Usage:
#   ./port_inspector.sh               # list all used ports with services
#   ./port_inspector.sh --free <port> # free a specific port
#   ./port_inspector.sh -h | --help   # show help
#
# Description:
#   - Lists all TCP/UDP ports currently in use with corresponding processes.
#   - Allows freeing (killing) a process occupying a specific port.
#   - Interactive confirmation before killing any process.

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
  -h, --help      Show this help message.

EXAMPLES:
  ./port_inspector.sh
  ./port_inspector.sh --free 8080
EOF
}

# ------------------------------------------------------------
# List ports and their services
# ------------------------------------------------------------
list_ports() {
    echo "============================================================"
    echo "Active Ports and Associated Services"
    echo "============================================================"
    # Use ss or netstat (ss preferred)
    if command -v ss >/dev/null 2>&1; then
        ss -tulpn | awk 'NR==1 || NR>1 {print}' 
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tulpn
    else
        echo "Neither 'ss' nor 'netstat' found. Install iproute2 or net-tools."
        exit 1
    fi
}

# ------------------------------------------------------------
# Free a port by killing its process
# ------------------------------------------------------------
free_port() {
    PORT=$1
    if [[ -z "$PORT" ]]; then
        echo "Error: No port specified."
        exit 1
    fi

    # Find PID using the port
    PID=$(lsof -ti :$PORT)
    if [[ -z "$PID" ]]; then
        echo "No process found using port $PORT."
        exit 1
    fi

    echo "Process using port $PORT:"
    lsof -i :$PORT

    read -p "Do you want to kill this process (PID: $PID)? (y/n): " ans
    if [[ "$ans" == "y" ]]; then
        kill -9 "$PID"
        echo "✔ Process $PID killed. Port $PORT is now free."
    else
        echo "✘ Operation cancelled. Port $PORT remains in use."
    fi
}

# ------------------------------------------------------------
# Main logic
# ------------------------------------------------------------
case "$1" in
    -h|--help)
        show_help
        ;;
    --free)
        free_port "$2"
        ;;
    "")
        list_ports
        ;;
    *)
        echo "Invalid option: $1"
        echo "Use --help to see usage."
        exit 1
        ;;
esac

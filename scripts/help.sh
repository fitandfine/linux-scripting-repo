#!/usr/bin/env bash
set -euo pipefail

# Default values
VERBOSE=0
FILE=""
if [[ $# -eq 0 ]]; then
    echo "No arguments have been passed to the script."
    exit 0
fi
# Function to show help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
  -h, --help       Show this help message
  -f, --file FILE  Specify a file to process
  -v, --verbose    Enable verbose mode
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--file)
            FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Use the options
if [[ $VERBOSE -eq 1 ]]; then
    echo "Verbose mode enabled"
fi

if [[ -n "$FILE" ]]; then
    echo "Processing file: $FILE"
fi
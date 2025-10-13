#!/usr/bin/env bash
# backup_dir.sh — Backup script with argument parsing, default, help, and space checks
# Usage:
#   ./backup_dir.sh [DIRECTORY]
# If no DIRECTORY is provided, backs up the HOME directory by default.
# Backups are stored as /tmp/<foldername>_backup_TIMESTAMP.tar.gz
# Author: Anup Chapain
set -euo pipefail

# ---------------------------
# Function: Show help message
# ---------------------------
show_help() {
cat << EOF
Usage: $0 [DIRECTORY]

Creates a compressed backup of DIRECTORY (default: \$HOME) in /tmp.
Checks if enough space is available before starting.

Options:
  --help     Show this help message and exit.

Examples:
  $0                 # Backup your home directory
  $0 /var/log        # Backup /var/log folder
EOF
}

# ---------------------------
# Parse Arguments
# ---------------------------
if [[ ${1:-} == "--help" || ${1:-} == "--h" ]]; then
  show_help
  exit 0
fi

SOURCE_DIR=${1:-$HOME}

# Validate directory
if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: '$SOURCE_DIR' is not a valid directory." >&2
  echo "Use --help for usage information." >&2
  exit 1
fi

# ---------------------------
# Disk space calculations
# ---------------------------
# Size of source directory in KB
SOURCE_SIZE_KB=$(du -sk "$SOURCE_DIR" | awk '{print $1}')

# Estimate compressed size as 60% of original (rough compression ratio)
EST_COMPRESSED_KB=$(( SOURCE_SIZE_KB * 60 / 100 ))

# Add 10% safety margin
TOTAL_NEEDED_KB=$(( SOURCE_SIZE_KB + EST_COMPRESSED_KB + SOURCE_SIZE_KB / 10 ))

# Available space in /tmp in KB
AVAILABLE_TMP_KB=$(df --output=avail /tmp | tail -1)

echo "Source folder size: $((SOURCE_SIZE_KB / 1024)) MB"
echo "Estimated archive size: $((EST_COMPRESSED_KB / 1024)) MB"
echo "Checking /tmp space..."
echo "Available in /tmp: $((AVAILABLE_TMP_KB / 1024)) MB"
echo "Estimated total needed (with margin): $((TOTAL_NEEDED_KB / 1024)) MB"

if (( AVAILABLE_TMP_KB < TOTAL_NEEDED_KB )); then
  echo "Error: Not enough space in /tmp to perform backup." >&2
  exit 1
fi

# ---------------------------
# Prepare paths
# ---------------------------
FOLDER_NAME=$(basename "$SOURCE_DIR")
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_TEMP="/tmp/${FOLDER_NAME}_backup_$DATE"
ARCHIVE="/tmp/${FOLDER_NAME}_backup_$DATE.tar.gz"

# Clean up temp folder if script fails
trap 'rm -rf "$BACKUP_TEMP"' EXIT

# ---------------------------
# Create Temporary Backup Folder
# ---------------------------
echo "Creating temporary backup folder: $BACKUP_TEMP"
mkdir -p "$BACKUP_TEMP"

# ---------------------------
# Copy Files
# ---------------------------
echo "Copying contents of $SOURCE_DIR ..."
for item in "$SOURCE_DIR"/*; do
  name=$(basename "$item")
  if [[ -d "$item" ]]; then
    echo "Copying directory: $name"
    cp -r "$item" "$BACKUP_TEMP/"
  elif [[ -f "$item" ]]; then
    echo "Copying file: $name"
    cp "$item" "$BACKUP_TEMP/"
  fi
done

# ---------------------------
# Create Compressed Archive
# ---------------------------
echo "Creating compressed archive: $ARCHIVE"
tar -czf "$ARCHIVE" -C /tmp "$(basename "$BACKUP_TEMP")"

# ---------------------------
# Clean Up
# ---------------------------
echo "Cleaning up temporary folder..."
rm -rf "$BACKUP_TEMP"
trap - EXIT  # disable cleanup trap after success

# ---------------------------
# Completion Message
# ---------------------------
echo "Backup completed successfully!"
echo "Archive stored at: $ARCHIVE"
echo ""
echo "Restore: tar -xzf $ARCHIVE -C /path/to/restore"
echo "View contents: tar -tzf $ARCHIVE"
echo "Delete backup: rm $ARCHIVE"

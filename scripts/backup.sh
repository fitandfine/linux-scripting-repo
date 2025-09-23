#!/usr/bin/env bash
# backup_dir.sh — Backup script with argument parsing, default, and help
# Usage:
#   ./backup_dir.sh [DIRECTORY]
# If no DIRECTORY is provided, backs up the HOME directory by default.
# Backups are stored as /tmp/<foldername>_backup_TIMESTAMP.tar.gz

set -euo pipefail

# ---------------------------
# Function: Show help message
# ---------------------------
show_help() {
cat << EOF
Usage: $0 [DIRECTORY]

Automates creating a compressed backup of the specified DIRECTORY.
If no DIRECTORY is provided, \$HOME will be used by default.

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
if [[ ${1:-} == "--help" ]]; then
  show_help
  exit 0
fi

# If no argument is provided, use HOME directory
SOURCE_DIR=${1:-$HOME}

# Validate that SOURCE_DIR exists and is a directory
if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: '$SOURCE_DIR' is not a valid directory." >&2
  echo "Use --help for usage information." >&2
  exit 1
fi

# Extract just the folder name to use in backup name
FOLDER_NAME=$(basename "$SOURCE_DIR")
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_TEMP="/tmp/${FOLDER_NAME}_backup_$DATE"
ARCHIVE="/tmp/${FOLDER_NAME}_backup_$DATE.tar.gz"

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

# ---------------------------
# Completion Message
# ---------------------------
echo "Backup completed successfully! Archive stored at $ARCHIVE"
echo ""
echo "Tip: Restore using: tar -xzf $ARCHIVE -C /path/to/restore"
echo "To view contents without extracting: tar -tzf $ARCHIVE"
echo "To delete the backup: rm $ARCHIVE"
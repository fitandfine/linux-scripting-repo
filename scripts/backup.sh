\#!/usr/bin/env bash

# backup\_dir.sh — Backup script with argument parsing, default, and help

# Usage:

# ./backup\_dir.sh \[DIRECTORY]

# If no DIRECTORY is provided, backs up the HOME directory by default.

# Backups are stored as /tmp/<foldername>\_backup\_TIMESTAMP.tar.gz

set -euo pipefail

# ---------------------------

# Function: Show help message

# ---------------------------

show\_help() {
cat << EOF
Usage: \$0 \[DIRECTORY]

Automates creating a compressed backup of the specified DIRECTORY.
If no DIRECTORY is provided, \$HOME will be used by default.

Options:
\--help     Show this help message and exit.

Examples:
\$0                 # Backup your home directory
\$0 /var/log        # Backup /var/log folder
EOF
}

# ---------------------------

# Parse Arguments

# ---------------------------

if \[\[ \${1:-} == "--help" ]]; then
show\_help
exit 0
fi

# If no argument is provided, use HOME directory

SOURCE\_DIR=\${1:-\$HOME}

# Validate that SOURCE\_DIR exists and is a directory

if \[\[ ! -d "\$SOURCE\_DIR" ]]; then
echo "Error: '\$SOURCE\_DIR' is not a valid directory." >&2
echo "Use --help for usage information." >&2
exit 1
fi

# Extract just the folder name to use in backup name

FOLDER\_NAME=\$(basename "\$SOURCE\_DIR")
DATE=\$(date +"%Y-%m-%d\_%H-%M-%S")
BACKUP\_TEMP="/tmp/\${FOLDER\_NAME}*backup*\$DATE"
ARCHIVE="/tmp/\${FOLDER\_NAME}*backup*\$DATE.tar.gz"

# ---------------------------

# Create Temporary Backup Folder

# ---------------------------

echo "Creating temporary backup folder: \$BACKUP\_TEMP"
mkdir -p "\$BACKUP\_TEMP"

# ---------------------------

# Copy Files

# ---------------------------

echo "Copying contents of \$SOURCE\_DIR ..."
for item in "\$SOURCE\_DIR"/\*; do
name=\$(basename "\$item")
if \[\[ -d "\$item" ]]; then
echo "Copying directory: \$name"
cp -r "\$item" "\$BACKUP\_TEMP/"
elif \[\[ -f "\$item" ]]; then
echo "Copying file: \$name"
cp "\$item" "\$BACKUP\_TEMP/"
fi
done

# ---------------------------

# Create Compressed Archive

# ---------------------------

echo "Creating compressed archive: \$ARCHIVE"
tar -czf "\$ARCHIVE" -C /tmp "\$(basename "\$BACKUP\_TEMP")"

# ---------------------------

# Clean Up

# ---------------------------

echo "Cleaning up temporary folder..."
rm -rf "\$BACKUP\_TEMP"

# ---------------------------

# Completion Message

# ---------------------------

echo "Backup completed successfully! Archive stored at \$ARCHIVE"
echo "\nTip: Restore using: tar -xzf \$ARCHIVE -C /path/to/restore"
echo "\nTo view contents without extracting: tar -tzf \$ARCHIVE"
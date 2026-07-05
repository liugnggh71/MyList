#!/bin/bash

################################################################################
# backup_one_file.sh - Creates timestamped backups of files in a 'bk' subdirectory
#
# Usage: ./backup_one_file.sh <file_to_backup>
#
# Features:
# - Creates backup in a 'bk' subdirectory of the file's directory
# - Preserves original file attributes (permissions, timestamps)
# - Shows last 10 backups after operation
# - Comprehensive error checking
# - Clear usage instructions
################################################################################

# Check if filename was provided
if [ $# -lt 1 ]; then
    echo "########################################"
    echo "ERROR: No file specified for backup"
    echo "USAGE: $0 <file_to_backup>"
    echo "########################################"
    exit 1
fi

# Verify the source file exists
if [ ! -f "$1" ]; then
    echo "ERROR: File '$1' does not exist or is not a regular file" >&2
    exit 2
fi

# Extract file components
file_path="$1"
file_name=$(basename "$file_path")
dir_name=$(dirname "$file_path")
backup_dir="${dir_name}/bk"

# Create backup directory if it doesn't exist
if ! mkdir -p "$backup_dir"; then
    echo "ERROR: Failed to create backup directory '$backup_dir'" >&2
    exit 3
fi

# Create timestamped backup filename
timestamp=$(date +%Y%m%d_%H%M%S)  # ISO 8601-ish format without colons
backup_file="${backup_dir}/${timestamp}.${file_name}"

# Perform the backup
if ! cp -p "$file_path" "$backup_file"; then
    echo "ERROR: Backup failed for file '$file_path'" >&2
    exit 4
fi

# Verify backup was created
if [ ! -f "$backup_file" ]; then
    echo "ERROR: Backup file '$backup_file' was not created" >&2
    exit 5
fi

# Display success message and recent backups
echo "SUCCESS: Created backup of '$file_path'"
echo "Backup saved as: $backup_file"
echo ""
echo "Last 10 backups in '$backup_dir':"
ls -lt "$backup_dir" | head -n 11  # Shows header plus 10 files

exit 0

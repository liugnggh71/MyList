#!/bin/bash
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author: Gang Liu
# Copyright 2025

# =============================================================================
# Script: Lev
# Purpose: Interactive menu to source Oracle environment .env files from $HOME.
# MUST BE SOURCED (e.g., `. Lev` or `source Lev`) unless using -h or -H.
# Also sources Oem and Clpt for extended setup.
# =============================================================================

# --- Color codes ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m'

# --- Logging functions ---
log() {
    echo -e "${GREEN}✅ [INFO] $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  [WARN] $1${NC}"
}

error() {
    echo -e "${RED}❌ [ERROR] $1${NC}" >&2
}

# --- Help ---
usage() {
    echo -e "📘 Usage: ${0##*/}"
    echo -e "ℹ️  MUST be sourced: ${YELLOW}. ${0##*/}${NC}"
    echo -e "  -h    ℹ️  Show brief help"
    echo -e "  -H    📖 Show detailed help"
    exit 0
}

help() {
    echo -e "

${GREEN}🌍 Lev${NC} - Oracle Environment Loader with Interactive Menu

${YELLOW}💡 PURPOSE:${NC}
This script:
  - 📂 Scans your \$HOME for \`.env\` files
  - 📋 Displays them in an interactive menu
  - 🔄 Sources your selected environment file
  - 🧩 Also sources \`Oem\` and \`Clpt\` for extended setup
  - 🖨️  Shows summary of ORACLE_HOME, SID, PDB, PATH

${RED}🚨 IMPORTANT:${NC}
You ${RED}MUST${NC} run this script with ${YELLOW}source${NC} or ${YELLOW}.${NC}:
    ${GREEN}. Lev${NC}

${YELLOW}📌 EXAMPLE:${NC}
  . Lev

${YELLOW}👨‍💻 AUTHOR:${NC}
  Gang Liu
"
    exit 0
}

# --- Parse args ---
while getopts ":hH" opt; do
    case $opt in
        h) usage ;;
        H) help ;;
        \?) error "Invalid option: -$OPTARG"; usage ;;
    esac
done

# --- Enforce sourcing ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] && [[ "$1" != "-h" ]] && [[ "$1" != "-H" ]] && [[ "$(echo "$1" | tr '[:upper:]' '[:lower:]')" != "--help" ]]; then
    error "Lev must be SOURCED (e.g., '. Lev') to work properly."
    error "Use: ${YELLOW}. Lev${NC}"
    exit 1
fi

# --- Source OEM ---
if command -v Oem >/dev/null 2>&1; then
    . "$(command -v Oem)"
    log "OEM environment setup loaded from: $(command -v Oem)"
else
    warn "Oem file not found — skipping OEM environment setup."
fi

# --- Find .env files ---
env_files=()
file_sizes=()

while IFS= read -r -d '' file; do
    env_files+=("$file")
    file_sizes+=("$(stat -c %s "$file" 2>/dev/null || echo 0)")
done < <(find "$HOME" -maxdepth 1 -name "*.env" -print0 2>/dev/null | sort -z)

if [ ${#env_files[@]} -eq 0 ]; then
    error "No .env files found in $HOME"
    return 1 2>/dev/null || exit 1
fi

# --- Display menu ---
log "🌍 Available .env files (sorted alphabetically):"
echo "--------------------------------------------"
for i in "${!env_files[@]}"; do
    filename=$(basename "${env_files[i]}")
    size=$(printf "%'d" "${file_sizes[i]}")
    if (( i % 2 == 0 )); then
        printf "${YELLOW}  %2d) %-20s %12s bytes${NC}\n" "$((i+1))" "$filename" "$size"
    else
        printf "${WHITE}  %2d) %-20s %12s bytes${NC}\n" "$((i+1))" "$filename" "$size"
    fi
done
echo "--------------------------------------------"

# --- User selection ---
selected_file=""
while true; do
    read -p "➡️  Select a file to source (1-${#env_files[@]}, or 'q' to quit): " choice
    [[ "$choice" =~ ^[Qq]$ ]] && { log "🚪 Exiting without sourcing."; return 0 2>/dev/null || exit 0; }
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#env_files[@]} )); then
        selected_file="${env_files[choice-1]}"
        break
    fi
    error "Invalid selection. Please enter a number between 1 and ${#env_files[@]}, or 'q' to quit."
done

# --- Source selected .env ---
log "🔄 Sourcing: $(basename "$selected_file") ($(printf "%'d" "$(stat -c %s "$selected_file")") bytes)"
if source "$selected_file"; then
    log "🎉 Environment file sourced successfully."
else
    error "Failed to source file: $selected_file"
    return 1 2>/dev/null || exit 1
fi

# --- Source Clpt (post-setup) ---
if command -v Clpt >/dev/null 2>&1; then
    . "$(command -v Clpt)"
    log "Post-environment setup loaded from: $(command -v Clpt)"
else
    warn "Clpt file not found — skipping post-environment setup."
fi

# --- Environment summary ---
echo -e "

${GREEN}📊 Current Environment Summary:${NC}
ORACLE_HOME    : ${ORACLE_HOME:-${YELLOW}Not set${NC}}
ORACLE_SID     : ${ORACLE_SID:-${YELLOW}Not set${NC}}
ORACLE_PDB_SID : ${ORACLE_PDB_SID:-${YELLOW}Not set${NC}}
PATH           : $PATH
"


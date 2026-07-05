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

#!/bin/bash

# =============================================================================
# Script: Lcd
# Purpose: Interactive menu to source environment scripts (cd_*) from a directory.
# MUST BE SOURCED (e.g., `. Lcd` or `source Lcd`) unless using -h or -H.
# Usage: . Lcd [directory] | . Lcd -h | . Lcd -H
# =============================================================================

# --- Color codes for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
WHITE='\033[37m'
NC='\033[0m' # No Color

# --- Function: Print status ---
log() {
    echo -e "${GREEN}✅ [INFO] $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  [WARN] $1${NC}"
}

error() {
    echo -e "${RED}❌ [ERROR] $1${NC}" >&2
}

# --- Function: Display short help ---
usage() {
    echo -e "📘 Usage: ${0##*/} [directory]"
    echo -e "ℹ️  MUST be sourced: ${YELLOW}. ${0##*/}${NC} [dir]${NC}"
    echo -e "  -h    ℹ️  Show brief help"
    echo -e "  -H    📖 Show detailed help"
    exit 0
}

# --- Function: Display long help ---
help() {
    echo -e "
${GREEN}📂 Lcd${NC} - Interactive Environment Script Launcher

${YELLOW}💡 PURPOSE:${NC}
This script helps you ${YELLOW}source${NC} environment setup scripts (typically named \`cd_*\`)
from a directory — commonly used to switch Oracle DB environments.

${RED}🚨 IMPORTANT:${NC}
You ${RED}MUST${NC} run this script with ${YELLOW}source${NC} or ${YELLOW}.${NC}:
    ${GREEN}. Lcd${NC}          → analyzes current directory
    ${GREEN}. Lcd /some/dir${NC} → analyzes specified directory

Running as \`${WHITE}./Lcd\` will fail — unless using -h/-H.

${YELLOW}📋 WHAT IT DOES:${NC}
  - 🔍 Scans for symbolic links and files named \`cd_*\`
  - 📋 Shows interactive menu to select one
  - 🔄 Sources the selected script in current shell (so env vars persist)

${YELLOW}🎛 OPTIONS:${NC}
  -h    ℹ️  Brief help
  -H    📖 Detailed help

${YELLOW}📌 EXAMPLE:${NC}
  . Lcd /u01/oracle/envs
  . Lcd

${YELLOW}👨‍💻 AUTHOR:${NC}
  Gang Liu — Custom DBA utility. Modify as needed.
"
    exit 0
}

# --- Parse command-line options ---
while getopts ":hH" opt; do
    case $opt in
        h)
            usage
            ;;
        H)
            help
            ;;
        \?)
            error "Invalid option: -$OPTARG"
            usage
            ;;
    esac
done

# --- CRITICAL: Enforce source mode unless help flag used ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] && [[ "$1" != "-h" ]] && [[ "$1" != "-H" ]] && [[ "$(echo "$1" | tr '[:upper:]' '[:lower:]')" != "--help" ]]; then
    error "Lcd must be SOURCED (e.g., '. Lcd') to work properly."
    error "Use: ${YELLOW}. Lcd${NC} [directory]${NC}"
    error "Help: ${GREEN}. Lcd -h${NC}"
    exit 1
fi

# --- Function: Show usage (used for errors) ---
show_usage() {
    echo "Usage: ${0##*/} [directory]" >&2
    echo "Must be sourced: . ${0##*/} [dir]" >&2
    echo "Use -h or -H for help." >&2
}

# --- Convert first parameter to lowercase for help check ---
help_param=$(echo "$1" | tr '[:upper:]' '[:lower:]')

# --- Check for help flags ---
if [[ "$help_param" == "-h" || "$help_param" == "--help" ]]; then
    usage
elif [[ "$1" == "-H" ]]; then
    help
fi

# --- Validate argument count ---
if [ $# -gt 1 ]; then
    error "Too many arguments"
    show_usage
    return 1 2>/dev/null || exit 1
fi

# --- Set target directory ---
target_dir="${1:-.}"

# --- Validate directory exists ---
if [ ! -d "$target_dir" ]; then
    error "Directory '$target_dir' does not exist or is not accessible"
    show_usage
    return 1 2>/dev/null || exit 1
fi

# --- Change to target directory ---
cd "$target_dir" || { error "Failed to cd to $target_dir"; return 1 2>/dev/null || exit 1; }

log "📂 Analyzing 'cd_*' entries in: $(pwd)"

# --- Initialize arrays ---
declare -a link_array
declare -a regular_array

# --- Find symbolic links with 'cd_' ---
link_entries=$(ls -l | awk '/ cd_/ && /^l/')
if [ -n "$link_entries" ]; then
    mapfile -t link_array <<< "$link_entries"
fi

# --- Find regular files/dirs with 'cd_' ---
regular_entries=$(ls -l | grep ' cd_' | grep -v ^l)
if [ -n "$regular_entries" ]; then
    mapfile -t regular_array <<< "$regular_entries"
fi

# --- Display regular entries ---
echo -e "\n${YELLOW}📁 Regular Files/Directories containing 'cd_':${NC}"
if [ ${#regular_array[@]} -eq 0 ]; then
    echo "No regular entries found"
else
    printf '%s\n' "${regular_array[@]}"
fi
echo "Total: ${#regular_array[@]}"

# --- Display symbolic links ---
echo -e "\n${YELLOW}🔗 Symbolic Links containing 'cd_':${NC}"
if [ ${#link_array[@]} -eq 0 ]; then
    echo "No symbolic links found"
else
    echo "Total: ${#link_array[@]}"
    echo -e "\n${GREEN}👇 Select a script to SOURCE:${NC}"
    echo "---------------------------"
    echo " 0) 🚪 Exit"
    for i in "${!link_array[@]}"; do
        if (( (i % 2) == 0 )); then
            printf "${YELLOW}%2d) %s${NC}\n" $((i+1)) "${link_array[$i]}"
        else
            printf "${WHITE}%2d) %s${NC}\n" $((i+1)) "${link_array[$i]}"
        fi
    done
    echo "---------------------------"

    # --- Get user selection ---
    read -p "➡️  Enter selection (0-${#link_array[@]}): " selection

    # --- Validate input ---
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || (( selection < 0 )) || (( selection > ${#link_array[@]} )); then
        error "Invalid selection"
        return 1 2>/dev/null || exit 1
    fi

    # --- Exit if 0 selected ---
    if (( selection == 0 )); then
        log "🚪 Exiting without sourcing any script."
        return 0 2>/dev/null || exit 0
    fi

    # --- Extract target script from selected link ---
    selected_link="${link_array[$((selection-1))]}"
    target_script=$(echo "$selected_link" | awk '{print $NF}' | sed 's/.*-> //')

    # --- Verify target exists ---
    if [ ! -f "$target_script" ]; then
        error "Target script '$target_script' not found in $(pwd)"
        return 1 2>/dev/null || exit 1
    fi

    # --- Source the script ---
    log "🔄 Sourcing: $target_script"
    source "$target_script"
    log "🎉 Environment updated successfully."
fi

# --- Final summary ---
echo -e "\n${GREEN}📊 Summary:${NC}"
echo "Regular entries: ${#regular_array[@]}"
echo "Symbolic links:  ${#link_array[@]}"
echo "Total entries:   $(( ${#regular_array[@]} + ${#link_array[@]} ))"


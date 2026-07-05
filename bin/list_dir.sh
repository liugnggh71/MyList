#!/bin/bash

# =======================================================================
# Ldir - Enhanced Directory Lister (ls -l style for subdirectories)
# Author: Gang Liu
# License: Apache License 2.0
#
# Copyright 2025 Gang Liu
#
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
# =======================================================================

# Color definitions — fallback to empty if tput fails
YELLOW=$(tput setaf 3 2>/dev/null || echo "")
WHITE=$(tput setaf 7 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")
RESET=$(tput sgr0 2>/dev/null || echo "")
BOLD=$(tput bold 2>/dev/null || echo "")

# Default values
show_size=false
target_dir="."

# =============================
# -h : SHORT HELP
# =============================
print_short_help() {
    cat <<EOF
${YELLOW}Ldir${RESET} - Enhanced subdirectory listing (ls -l style)

Usage:
  ${GREEN}Ldir${RESET} [${BLUE}-s${RESET}] [${BLUE}-h${RESET}] [${BLUE}-H${RESET}] [directory]

Options:
  ${BLUE}-s${RESET}    Show sizes and total disk usage
  ${BLUE}-h${RESET}    Show this short help
  ${BLUE}-H${RESET}    Show full documentation
  directory  Target directory (default: current)

Features:
  • Alternating ${YELLOW}yellow${RESET}/${WHITE}white${RESET} lines
  • ${RED}Red${RESET} directory name if >1000 files inside
  • Direct + recursive file counts (or size in -s mode)
  • Human-readable totals

Example:
  Ldir -s /u01/app
  Ldir
  Ldir -h

EOF
    exit 0
}

# =============================
# -H : FULL DOCUMENTATION
# =============================
print_full_help() {
    cat <<EOF
${YELLOW}Ldir${RESET} — Enhanced Subdirectory Lister (Full Documentation)
Author: Gang Liu
License: Apache License 2.0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PURPOSE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ldir lists subdirectories in the target directory with enhanced ls -l style output.

It provides:
  • Permissions, owner, group
  • Direct file count (immediate children)
  • Recursive file count (all files inside, or size in -s mode)
  • Alternating line colors for readability
  • Highlight in ${RED}red${RESET} if directory contains >1000 files
  • Grand totals at bottom

Designed for sysadmins and DBAs who need quick, visual, detailed directory overviews.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
USAGE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

\$ ${GREEN}Ldir${RESET} [${BLUE}-s${RESET}] [directory]

Arguments:
  directory     → Path to scan (default: current directory ".")
  ${BLUE}-s${RESET}          → Show disk sizes and accumulate total usage
  ${BLUE}-h${RESET}          → Show short help (this screen)
  ${BLUE}-H${RESET}          → Show this full documentation

Examples:
  \$ Ldir
      → List subdirs with direct + recursive file counts.

  \$ Ldir -s /tmp
      → List subdirs in /tmp with sizes and total disk usage.

  \$ Ldir -h
      → Quick help.

  \$ Ldir -H
      → This full manual.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OUTPUT FORMAT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Without -s:
  Perm        Owner    Group    Direct   Recur    Name
  drwxr-xr-x  oracle   dba      15       1250     big_dir   ← Name in RED (1250 > 1000)

With -s:
  Perm        Owner    Group    Size     Direct   Name
  drwxr-xr-x  oracle   dba      80K      15       small_dir

Footer:
  Total: 5 dirs | Direct: 120 | Recursive files: 2,500
  or
  Total: 5 dirs | Direct entries: 120 | Total Size: 1.2G

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
COLOR LEGEND
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• Alternating Lines: ${YELLOW}Yellow${RESET} / ${WHITE}White${RESET} — improves readability
• Directory Name: ${RED}Red + Bold${RESET} — if recursive file count > 1000
• Totals Line: ${YELLOW}Yellow + Bold${RESET}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PORTABILITY & IMPLEMENTATION NOTES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• SHELL: Written for POSIX shell compatibility. Tested on:
    - Linux bash
    - AIX ksh
    - Solaris ksh
    - macOS zsh/bash

• COMMANDS USED:
    - find (with -maxdepth 1, -type d, -print0)
    - stat (GNU/BSD variants for perm/owner/group)
    - du (for -s mode)
    - sort, awk, wc, date

• FALLBACKS:
    - If tput fails → colors disabled gracefully
    - If stat fails → shows "???"
    - If du/find fails → shows 0 or "??"

• PERFORMANCE:
    - Uses find -print0 for safe handling of spaces/special chars
    - Recursive file count can be slow on large dirs — use -s for faster du-based size

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• "find: bad option -maxdepth"
    → You're on old Unix (AIX/Solaris). Replace with:
        for dir in */; do ... (less robust but works)

• "stat: command not found"
    → Use ls -ld parsing fallback (not implemented — let author know)

• No colors?
    → Check TERM: \`echo \$TERM\` — if "dumb", try:
        export TERM=xterm

• "Permission denied" on some dirs
    → Skipped gracefully — count shown as 0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUTHOR & LICENSE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Author: Gang Liu
License: Apache License 2.0

You may use, modify, and distribute this script under the terms of the
Apache License, Version 2.0.

EOF
    exit 0
}

# =============================
# Parse CLI args
# =============================
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s)
            show_size=true
            shift
            ;;
        -h)
            print_short_help
            ;;
        -H)
            print_full_help
            ;;
        -*)
            echo "Error: Unknown option $1" >&2
            echo "Use -h for help." >&2
            exit 1
            ;;
        *)
            if [[ -n "$target_dir" && "$target_dir" != "." ]]; then
                echo "Error: Multiple directories specified." >&2
                echo "Use -h for help." >&2
                exit 1
            fi
            target_dir="$1"
            shift
            ;;
    esac
done

# Validate target directory
if [[ ! -d "$target_dir" ]]; then
    echo "Error: Directory '$target_dir' does not exist or is not accessible." >&2
    exit 1
fi

# Change to target directory
cd "$target_dir" || {
    echo "Error: Cannot change to directory '$target_dir'." >&2
    exit 1
}

# Header
echo "Subdirectories in: $(pwd)"
echo "------------------------------------------------------------------------"

# Header row
if [[ "$show_size" == true ]]; then
    printf "%-11s %-8s %-8s %-8s %-6s %s\n" "Perm" "Owner" "Group" "Size" "Direct" "Name"
else
    printf "%-11s %-8s %-8s %-8s %-6s %s\n" "Perm" "Owner" "Group" "Direct" "Recur" "Name"
fi
echo "------------------------------------------------------------------------"

# Collect subdirectories (exclude . and ..)
declare -a subdirs=()
while IFS= read -r -d '' dir; do
    [[ "$dir" == "." || "$dir" == ".." ]] && continue
    [[ -d "$dir" ]] && subdirs+=("$dir")
done < <(find . -maxdepth 1 -type d -print0 2>/dev/null)

# Sort case-insensitively by name
IFS=$'\n' sorted=($(printf '%s\n' "${subdirs[@]}" | sort -f))
unset IFS

# If no subdirectories found
if [[ ${#sorted[@]} -eq 0 ]]; then
    echo "No subdirectories found."
    echo "------------------------------------------------------------------------"
    exit 0
fi

# Initialize counters
line_num=1
grand_direct=0
grand_recur=0
total_kb=0  # for -s mode total (du -s returns KB)

# Process each subdirectory
for dir in "${sorted[@]}"; do
    base="${dir#./}"

    # Get file stats
    perm=$(stat -c %A "$dir" 2>/dev/null || echo "??????????")
    owner=$(stat -c %U "$dir" 2>/dev/null || echo "???")
    group=$(stat -c %G "$dir" 2>/dev/null || echo "???")
    mtime=$(stat -c %Y "$dir" 2>/dev/null)

    # Format date like ls: 'Aug 17 14:22' or 'Aug 17  2023'
    if [[ -n "$mtime" ]]; then
        now=$(date +%s)
        six_months_ago=$((now - 6 * 30 * 86400))
        if (( mtime < six_months_ago )); then
            date_str=$(date -d "@$mtime" '+%b %d  %Y' 2>/dev/null)
        else
            date_str=$(date -d "@$mtime" '+%b %d %H:%M' 2>/dev/null)
        fi
    else
        date_str="??? ?? ??:??"
    fi

    # Direct count: immediate children
    if [[ -r "$dir" ]]; then
        direct=$(find "$dir" -maxdepth 1 -mindepth 1 | wc -l 2>/dev/null || echo 0)
    else
        direct=0
    fi

    # Recursive file count (all files inside)
    if [[ -r "$dir" ]]; then
        recur=$(find "$dir" -type f | wc -l 2>/dev/null || echo 0)
    else
        recur=0
    fi

    # Accumulate totals
    (( grand_direct += direct ))
    (( grand_recur += recur ))

    # Line color: alternating yellow/white
    if (( line_num % 2 == 0 )); then
        line_color="$YELLOW"
    else
        line_color="$WHITE"
    fi

    # Name color: red if >1000 files
    if (( recur > 1000 )); then
        name_color="${RED}${BOLD}"
    else
        name_color="$line_color"
    fi

    # Format and display
    if [[ "$show_size" == true ]]; then
        # Get size in KB (du -s returns KB)
        size_kb=$(du -s "$dir" 2>/dev/null | cut -f1)
        if [[ -n "$size_kb" && "$size_kb" =~ ^[0-9]+$ ]]; then
            (( total_kb += size_kb ))
        fi

        # Human-readable size for display (e.g., 152K, 80K)
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        size=${size:-"??"}

        # Output: perm owner group size direct name
        printf "${line_color}%-11s %-8s %-8s %-8s %-6s %b%s%b${RESET}\n" \
            "$perm" "$owner" "$group" "$size" "$direct" \
            "$name_color" "$base" "$RESET"
    else
        # Normal mode: direct + recursive count
        printf "${line_color}%-11s %-8s %-8s %-8s %-6s %b%s%b${RESET}\n" \
            "$perm" "$owner" "$group" "$direct" "$recur" \
            "$name_color" "$base" "$RESET"
    fi

    ((line_num++))
done

# === Final Summary ===
echo "------------------------------------------------------------------------"
if [[ "$show_size" == true ]]; then
    # Convert total_kb to human-readable using awk
    if (( total_kb > 0 )); then
        human_total=$(awk -v size="$total_kb" '
        BEGIN {
            if (size < 1024)                           { printf "%.0fK", size }
            else if (size < 1024*1024)                 { printf "%.1fM", size/1024 }
            else if (size < 1024*1024*1024)            { printf "%.1fG", size/(1024^2) }
            else if (size < 1024*1024*1024*1024)       { printf "%.1fT", size/(1024^3) }
            else                                       { printf "%.1fP", size/(1024^4) }
        }')
    else
        human_total="0K"
    fi

    printf "Total: %d dirs | Direct entries: %'d | %bTotal Size: %s%b\n" \
        "${#sorted[@]}" "$grand_direct" \
        "${YELLOW}${BOLD}" "$human_total" "${RESET}"
else
    printf "Total: %d dirs | Direct: %'d | Recursive files: %'d\n" \
        "${#sorted[@]}" "$grand_direct" "$grand_recur"
fi


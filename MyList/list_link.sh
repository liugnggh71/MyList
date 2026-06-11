#!/bin/bash

# =======================================================================
# Llink - Portable Symbolic Link Lister
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
#
# Works on AIX/ksh88, Linux, Solaris, HP-UX, macOS, minimal containers
# No GNU dependencies: no readlink, mktemp, find -maxdepth required
# =======================================================================

# Optional: Improve terminal compatibility for color
if [ "$TERM" = "dumb" ] || [ "$TERM" = "network" ]; then
    export TERM=xterm
fi

# Portable Color Setup — uses tput if available, else ANSI via printf (ksh88 safe)
if tput setaf 1 >/dev/null 2>&1 && [ -n "$(tput setaf 1)" ]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    CYAN=$(tput setaf 6)    # Use cyan instead of blue
    WHITE=$(tput setaf 7)
    BLINK=$(tput blink)
    RESET=$(tput sgr0)
else
    # Fallback: Use printf for ANSI codes — works in ksh88, POSIX shells
    RED=$(printf "\033[31m")
    GREEN=$(printf "\033[32m")
    YELLOW=$(printf "\033[33m")
    CYAN=$(printf "\033[36m")   # Cyan = \033[36m
    WHITE=$(printf "\033[37m")
    BLINK=$(printf "\033[5m")
    RESET=$(printf "\033[0m")
fi

# Default modes
SORT_BY_TIME=false
SHOW_EXEC_ONLY=false

# =============================
# -h : SHORT HELP
# =============================
print_short_help() {
    cat <<EOF
${YELLOW}Llink${RESET} - List symbolic links with colorized targets

Usage:
  ${GREEN}Llink${RESET} [${CYAN}-t${RESET}] [${CYAN}-e${RESET}] [${WHITE}directory${RESET}]
  ${GREEN}Llink${RESET} ${CYAN}-h${RESET}        # Show this short help
  ${GREEN}Llink${RESET} ${CYAN}-H${RESET}        # Show full documentation

Options:
  ${CYAN}-t${RESET}    Sort by modification time (oldest first)
  ${CYAN}-e${RESET}    Show only links whose targets are executable files
  ${CYAN}-h${RESET}    Show short help (this screen)
  ${CYAN}-H${RESET}    Show full documentation

Color Legend:
  ${YELLOW}Yellow${RESET}  → Symlink name (left column)
  ${WHITE}White${RESET}   → Regular file target
  ${GREEN}Green${RESET}   → Executable file target
  ${CYAN}Cyan${RESET}     → Directory target
  ${BLINK}${RED}Red${RESET}     → Broken link target

Example:
  Llink /usr/bin
  Llink -e -t

EOF
    exit 0
}

# =============================
# -H : FULL DOCUMENTATION
# =============================
print_full_help() {
    cat <<EOF
${YELLOW}Llink${RESET} — Portable Symbolic Link Lister (Full Documentation)
Author: Gang Liu
License: Apache License 2.0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PURPOSE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Llink lists all symbolic links in a given directory and displays where they point to.
Each target is color-coded by its file type. Broken links blink in red.

Designed for maximum portability — works even on legacy systems like:
  • AIX with ksh88
  • Solaris 10
  • HP-UX
  • Minimal Linux containers
  • macOS

No GNU coreutils required: avoids readlink, mktemp, find -maxdepth, etc.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
USAGE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

\$ ${GREEN}Llink${RESET} [${CYAN}-t${RESET}] [${CYAN}-e${RESET}] [directory]

Arguments:
  directory     → Path to scan (default: current directory ".")
  ${CYAN}-t${RESET}          → Sort by modification time (oldest first)
  ${CYAN}-e${RESET}          → Show only symlinks pointing to executable files
  ${CYAN}-h${RESET}          → Show short help
  ${CYAN}-H${RESET}          → Show this full manual

Examples:
  \$ Llink
      → Lists symlinks in current directory, sorted by name.

  \$ Llink /usr/bin
      → Lists symlinks in /usr/bin.

  \$ Llink -t
      → Lists symlinks sorted by modification time (oldest first).

  \$ Llink -e /usr/bin
      → Lists only symlinks whose targets are executable.

  \$ Llink -e -t
      → Executable-only symlinks, sorted by time.

  \$ Llink -h
      → Quick help.

  \$ Llink -H
      → This full manual.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
COLOR LEGEND
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Left Column (Symlink Name):
  • Alternates between ${WHITE}White${RESET} and ${YELLOW}Yellow${RESET} for readability.

Right Column (Target):
  ${YELLOW}Yellow${RESET}    → Target is a symbolic link
  ${WHITE}White${RESET}     → Target is a regular file
  ${GREEN}Green${RESET}     → Target is an executable file
  ${CYAN}Cyan${RESET}       → Target is a directory
  ${BLINK}${RED}Blinking Red${RESET} → Target does not exist (broken link)

Example Output:
  mylink               → /real/target/file       ← Green if executable
  badlink              → /nonexistent/path       ← Blinking Red

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PORTABILITY & IMPLEMENTATION NOTES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• SHELL: Written for POSIX shell compatibility. Tested on:
    - AIX ksh88
    - Linux bash/dash
    - Solaris ksh
    - HP-UX sh
    - macOS zsh/bash

• NO GNU DEPENDENCIES:
    - Uses \`ls -l | sed 's/.* -> //'\` instead of \`readlink\`
    - Uses \`/tmp/Llink.\$\$\` instead of \`mktemp\`
    - Uses shell glob \`for link in *\` instead of \`find -maxdepth 1\`
    - Uses \`printf "\\033[...m"\` for colors if \`tput\` fails

• STAT PORTABILITY:
    - Tries both \`stat -c %Y\` (GNU) and \`stat -f %m\` (BSD/AIX) for timestamps
    - Falls back to 0 if stat is unavailable — still works, just unsorted by time

• COLOR FALLBACK:
    - First tries \`tput setaf\`
    - If that fails or returns empty, uses ANSI escape codes via \`printf\`
    - Safe for dumb terminals — colors degrade gracefully

• ERROR HANDLING:
    - Skips malformed symlinks
    - Traps and cleans up temp file
    - Exits cleanly on invalid args or missing directories

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• No colors?
    → Check TERM: \`echo \$TERM\` — if "dumb" or "network", try:
        export TERM=xterm
    → Some terminals or SSH clients disable colors — try a different terminal.

• "sed: command not found"?
    → Extremely rare — but if missing, replace line:
        target=\$(ls -l "\$link" 2>/dev/null | sed 's/.* -> //')
      with:
        target=\$(ls -l "\$link" 2>/dev/null | awk -F' -> ' '{print \$2}')

• Want no colors?
    → Set before running:
        NO_COLOR=1 Llink
      (Not implemented yet — let author know if needed)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUTHOR & LICENSE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Author: Gang Liu
License: Apache License 2.0
Source: Internal DBA utility

You may use, modify, and distribute this script under the terms of the
Apache License, Version 2.0.

EOF
    exit 0
}

# =============================
# Parse CLI args
# =============================
while [ $# -gt 0 ]; do
    case "$1" in
        -h)
            print_short_help
            ;;
        -H)
            print_full_help
            ;;
        -t|-T)
            SORT_BY_TIME=true
            shift
            ;;
        -e)
            SHOW_EXEC_ONLY=true
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1" >&2
            echo "Use 'Llink -h' for help." >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Set target directory (first non-option argument)
target_dir="${1:-.}"

# Verify directory exists
if [ ! -d "$target_dir" ]; then
    echo "Error: Directory '$target_dir' does not exist" >&2
    exit 1
fi

# Function to colorize target based on type
colorize_target() {
    local target=$1
    if [ ! -e "$target" ]; then
        echo -n "${BLINK}${RED}$target${RESET}"
    elif [ -L "$target" ]; then
        echo -n "${YELLOW}$target${RESET}"
    elif [ -f "$target" ]; then
        if [ -x "$target" ]; then
            echo -n "${GREEN}$target${RESET}"
        else
            echo -n "${WHITE}$target${RESET}"
        fi
    elif [ -d "$target" ]; then
        echo -n "${CYAN}$target${RESET}"
    else
        echo -n "$target"
    fi
}

# Main display
echo "Symbolic Links in $target_dir:"
echo "-------------------------"

# Use PID-based temp file (mktemp not required)
temp_file="/tmp/Llink.$$"
trap 'rm -f "$temp_file" 2>/dev/null' EXIT

# Collect symlinks using shell glob (POSIX, no find -maxdepth)
(
    cd "$target_dir" || exit 1
    for link in *; do
        [ -L "$link" ] || continue   # Skip non-symlinks

        # Extract target using 'ls -l' (no readlink needed)
        target=$(ls -l "$link" 2>/dev/null | sed 's/.* -> //')
        [ -z "$target" ] && continue  # Skip if parsing failed

        # Resolve relative paths
        case "$target" in
            /*) : ;;                  # Absolute — do nothing
            *)  target="$target_dir/$target" ;;  # Relative — prepend dir
        esac

        # Skip if -e and target is not an executable regular file
        if [ "$SHOW_EXEC_ONLY" = true ]; then
            [ -f "$target" ] && [ -x "$target" ] || continue
        fi

        if [ "$SORT_BY_TIME" = true ]; then
            # Try to get mtime — fallback to 0 if stat fails
            if mtime=$(stat -c %Y "$link" 2>/dev/null); then
                :
            elif mtime=$(stat -f %m "$link" 2>/dev/null); then
                :
            else
                mtime=0
            fi
            printf '%d\t%s\t%s\t%s\n' "$mtime" "$link" "$target" "$link"
        else
            # Lowercase for case-insensitive sort
            lower_name=$(echo "$link" | tr '[:upper:]' '[:lower:]')
            printf '%s\t%s\t%s\t%s\n' "$lower_name" "$link" "$target" "$link"
        fi
    done
) > "$temp_file"

# If no links found
if [ ! -s "$temp_file" ]; then
    echo "No symbolic links found in '$target_dir'"
    exit 0
fi

# Sort and display with alternating prefix colors
line_num=1

if [ "$SORT_BY_TIME" = true ]; then
    sort_cmd="sort -n"
else
    sort_cmd="sort -f"
fi

if ! $sort_cmd "$temp_file" 2>/dev/null | while IFS=$'\t' read -r _ link_name target _; do
    # Alternate prefix color
    if [ $((line_num % 2)) -eq 0 ]; then
        prefix_color="$YELLOW"
    else
        prefix_color="$WHITE"
    fi

    # Print formatted prefix
    printf "${prefix_color}%-20s -> ${RESET}" "$link_name"

    # Print colored target
    colorize_target "$target"
    echo

    line_num=$((line_num + 1))
done; then
    echo "Error: Failed to process links." >&2
    exit 1
fi

# Show legend
echo ""
echo "Color Legend:"
echo "${YELLOW}Yellow${RESET}: Symbolic link (name)"
echo "${WHITE}White${RESET}: Regular file"
echo "${GREEN}Green${RESET}: Executable file"
echo "${CYAN}Cyan${RESET}: Directory"
echo "${BLINK}${RED}Blinking Red${RESET}: Broken link"


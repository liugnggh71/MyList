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
# Script: Lfile
# Purpose: List and color-code files in a directory with emoji-enhanced output.
# Usage: Lfile [directory] | Lfile -h | Lfile -H
# =============================================================================

# --- Color definitions using tput (portable) ---
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
PINK=$(tput setaf 5)
LIGHT_BLUE=$(tput setaf 6)
WHITE=$(tput setaf 7)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# --- Function: Print status ---
log() {
    echo "${GREEN}✅ [INFO]${RESET} $1"
}

warn() {
    echo "${YELLOW}⚠️  [WARN]${RESET} $1" >&2
}

error() {
    echo "${RED}❌ [ERROR]${RESET} $1" >&2
}

# --- Function: Display short help ---
usage() {
    echo "📘 Usage: ${0##*/} [directory]"
    echo "ℹ️  List and color-code files in specified directory."
    echo "  -h, -H    📖 Show detailed help with color legend"
    exit 0
}

# --- Function: Display long help ---
help() {
    cat <<EOF
${BOLD}${GREEN}📁 Lfile${RESET} - Color-Coded File Lister with Emoji Enhancements

${YELLOW}💡 PURPOSE:${RESET}
Lists files in a directory with intelligent color-coding based on file type.
Perfect for quickly identifying executables, archives, images, documents, etc.

${YELLOW}🎨 COLOR LEGEND:${RESET}
${LIGHT_BLUE}🔵 Light Blue${RESET}: Binary executable (ELF/PE/Mach-O)
${BLUE}🟦 Blue${RESET}: Library files (.so, .a, .dll, .lib)
${GREEN}🟢 Green${RESET}: Executable scripts
${RED}🔴 Red${RESET}: Archive files (zip, tar, gz, 7z, rar)
${PINK}🟣 Pink${RESET}: Image files
${YELLOW}🟡 Yellow${RESET}: Document files (pdf, doc, html, txt)
${WHITE}⚪ White${RESET}: Other files

${YELLOW}🎛 OPTIONS:${RESET}
  -h, -H    Show this help

${YELLOW}📌 EXAMPLE:${RESET}
  ${GREEN}./Lfile${RESET}              → current directory
  ${GREEN}./Lfile /usr/bin${RESET}    → specific directory

${YELLOW}👨‍💻 AUTHOR:${RESET}
  Gang Liu — Custom utility. Modify as needed.

EOF
    exit 0
}

# --- Parse command-line options ---
if [[ "$1" == "-h" ]] || [[ "$1" == "-H" ]]; then
    help
fi

# --- Validate argument count ---
if [[ $# -gt 1 ]]; then
    error "Too many arguments"
    usage
    exit 1
fi

# --- Set target directory ---
target_dir="${1:-.}"

# --- Validate directory exists ---
if [[ ! -d "$target_dir" ]]; then
    error "Directory '$target_dir' does not exist"
    exit 1
fi

# --- Function: Colorize filename based on type ---
colorize_filename() {
    local file="$1"
    local mime_type=""
    local extension="${file##*.}"

    # Get MIME type if file command exists
    if command -v file >/dev/null 2>&1; then
        mime_type=$(file -b --mime-type "$file" 2>/dev/null)
    fi

    # Color logic
    if [[ "$mime_type" == *"executable"* ]] && [[ "$mime_type" == *"ELF"* || "$mime_type" == *"PE"* || "$mime_type" == *"Mach-O"* ]]; then
        echo -n "${LIGHT_BLUE}$file${RESET}"
    elif [[ "$extension" == "so" ]] || [[ "$extension" == "a" ]] || [[ "$extension" == "lib" ]] || [[ "$extension" == "dll" ]] ||
         [[ "$mime_type" == *"shared library"* ]] || [[ "$mime_type" == *"archive"* && ! "$mime_type" == *"application/x-gzip"* ]]; then
        echo -n "${BLUE}$file${RESET}"
    elif [[ -x "$file" ]] && [[ ! "$mime_type" == *"ELF"* ]] && [[ ! "$mime_type" == *"PE"* ]]; then
        echo -n "${GREEN}$file${RESET}"
    elif [[ "$mime_type" == *"zip"* ]] || [[ "$mime_type" == *"tar"* ]] || [[ "$mime_type" == *"gzip"* ]] ||
         [[ "$mime_type" == *"bzip2"* ]] || [[ "$mime_type" == *"7z"* ]] || [[ "$mime_type" == *"rar"* ]]; then
        echo -n "${RED}$file${RESET}"
    elif [[ "$mime_type" == *"image"* ]]; then
        echo -n "${PINK}$file${RESET}"
    elif [[ "$mime_type" == *"pdf"* ]] || [[ "$mime_type" == *"msword"* ]] || [[ "$mime_type" == *"vnd.openxmlformats-officedocument"* ]] ||
         [[ "$mime_type" == *"html"* ]] || [[ "$mime_type" == *"text"* ]] || [[ "$extension" == "txt" ]] || [[ "$extension" == "log" ]]; then
        echo -n "${YELLOW}$file${RESET}"
    else
        echo -n "${WHITE}$file${RESET}"
    fi
}

# --- Main execution ---
log "📂 Listing files in: $target_dir"
echo "----------------------------------------------------------------------"

# Counter and line number
line_num=1
file_count=0

# Use find + sort + while loop with better quoting and IFS handling
while IFS= read -r -d '' fullpath; do
    [[ ! -f "$fullpath" ]] && continue  # safety check

    filename=$(basename "$fullpath")
    file_info=$(ls -l "$fullpath" 2>/dev/null)
    [[ -z "$file_info" ]] && continue

    # Split file info
    read -ra parts <<< "$file_info"

    # Choose alternating row color for prefix
    if (( line_num % 2 == 0 )); then
        prefix_color="${YELLOW}"
    else
        prefix_color="${WHITE}"
    fi

    # Print all parts except filename
    for ((i=0; i<${#parts[@]}-1; i++)); do
        printf "%s%s%s " "$prefix_color" "${parts[i]}" "$RESET"
    done

    # Print colorized filename
    colorized_name=$(colorize_filename "$filename")
    printf "%s\n" "$colorized_name"

    ((line_num++))
    ((file_count++))

done < <(find "$target_dir" -maxdepth 1 -type f -print0 | sort -fz)

echo "----------------------------------------------------------------------"
log "📊 Found $file_count files."


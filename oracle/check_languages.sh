#!/usr/bin/env bash
#
# Author: Anup Chapain
# Date: 2025-10-18
# Description:
#   This script tests which Oracle Cloud documentation language URLs return HTTP 200 (OK).
#   It reads a list of language codes and names from a file (languages.txt),
#   replaces the "en" in the base URL with each code,
#   and performs the check in parallel.
#
#   Supported URLs are written to supported_languages.txt
#   Unsupported URLs are written to unsupported_languages.txt
#
#   This demonstrates parallel execution and robust reporting.

#-----------------------------
# essential safety and error-checking
#-----------------------------------------

set -euo pipefail

# -----------------------------
# CONFIGURATION SECTION
# -----------------------------
BASE_URL="https://docs.oracle.com"       # Root of Oracle documentation
LANG_FILE="languages.txt"                # Input list of languages
SUPPORTED_FILE="supported_languages.txt" # Output for supported languages
UNSUPPORTED_FILE="unsupported_languages.txt" # Output for unsupported languages
MAX_JOBS=10                              # Number of concurrent parallel checks

# -----------------------------
# PRE-RUN VALIDATION
# -----------------------------

# Clear previous outputs
> "$SUPPORTED_FILE"
> "$UNSUPPORTED_FILE"

# Verify language list exists
if [ ! -f "$LANG_FILE" ]; then
  echo "❌ Error: Language list file ($LANG_FILE) not found!"
  exit 1
fi

# Count total number of lines (languages) to process
TOTAL_LANGS=$(wc -l < "$LANG_FILE")
COMPLETED=0

echo "🔍 Checking Oracle Docs language support..."
echo "-------------------------------------------"
echo "Total languages to check: $TOTAL_LANGS"
echo

# -----------------------------
# FUNCTION DEFINITIONS
# -----------------------------

# Function: check_language
# Purpose : Tests one language URL and records the result.
check_language() {
  local code="$1"
  local name="$2"
  local test_url="${BASE_URL}/${code}/cloud/"
  local status_code

  # Perform silent curl request (no output, only HTTP code)
  status_code=$(curl -s -o /dev/null -w "%{http_code}" "$test_url")
  
  # Thread-safe file writes using subshell + lock
  if [ "$status_code" -eq 200 ]; then
    echo "✅ Supported: $name ($code) -> $test_url"
    echo "$name ($code): $test_url" >> "$SUPPORTED_FILE"
    
  else
    echo "❌ Not supported: $name ($code) [$status_code]"
    echo "$name ($code): $test_url [$status_code]" >> "$UNSUPPORTED_FILE"
    
  fi
#Initial idea was to show progress, but it gets messy with concurrent jobs
#-----------------------------
  # Increment progress safely (each job reports completion to the console)
  # /dev/tty ensures output goes to the parent/controlling terminal even from background jobs

  #echo "$((++COMPLETED)) / $TOTAL_LANGS completed" > /dev/tty

  # /dev/tty:
# This special device file refers to the controlling terminal (the screen/keyboard
# session) of the process that opens it. Writing to /dev/tty forces output to the
# user's screen immediately, bypassing any shell redirection or buffering of stdout.
# It is essential for displaying interactive prompts or real-time status messages
# from background jobs, ensuring they are always visible to the user.

# 🛑 PROGRESS TRACKING FAILURE NOTE (Subshell Variable Scope)
# -----------------------------------------------------------
# The initial attempt to track progress using a simple variable counter (e.g., ((COMPLETED++)))
# failed because background jobs ('&') run in isolated environments called subshells.
#
# 1. VARIABLE ISOLATION: Each subshell receives its own COPY of the parent script's
#    variables (like $COMPLETED) and can only modify its own copy.
# 2. NO RETURN: When the subshell exits, its updated variable value is DESTROYED and 
#    is NEVER passed back to the parent shell.
#
# This means the parent script's counter remains inaccurate (often 0).
#
# A reliable solution requires an Inter-Process Communication (IPC) mechanism, such
# as a dedicated temporary file or named pipe, to allow the concurrent subshells
# to safely communicate their completion status to the parent script.

}


# -----------------------------
# MAIN EXECUTION LOOP
# -----------------------------

# Use GNU parallel-style background jobs for concurrency
while read -r code name; do
  # Run each check in background to speed things up
  check_language "$code" "$name" &
  
  # Limit concurrency to $MAX_JOBS
  while (( $(jobs -r | wc -l) >= MAX_JOBS )); do
    sleep 0.2
  done
done < "$LANG_FILE"

# Wait for all background jobs to finish
wait

# Move to a new line after progress bar finishes
echo
echo "-------------------------------------------"
echo "✅ Scan complete!"
echo "📄 $(wc -l < "$SUPPORTED_FILE") Supported languages:  see  $SUPPORTED_FILE"
echo "📄 $(wc -l < "$UNSUPPORTED_FILE") Unsupported languages: see $UNSUPPORTED_FILE"

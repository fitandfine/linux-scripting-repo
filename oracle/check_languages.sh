#!/usr/bin/env bash
#
# Author: Anup Chapain
# Date: 2025-10-18
# Description:
#   This script tests which Oracle Cloud documentation language URLs return HTTP 200 (OK).
#   It reads a list of language codes and names from a file (languages.txt),
#   replaces the "en" in the base URL with each code,
#   and performs the check in parallel with a live progress bar.
#
#   Supported URLs are written to supported_languages.txt
#   Unsupported URLs are written to unsupported_languages.txt
#
#   This demonstrates parallel execution, progress tracking, and robust reporting.

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

  # Increment progress safely (each job reports completion)
  ((COMPLETED++))
  show_progress "$COMPLETED" "$TOTAL_LANGS"
}

# Function: show_progress
# Purpose : Draws a simple text-based progress bar.
show_progress() {
  local done=$1
  local total=$2
  local cols=$(tput cols 2>/dev/null || echo 80)
  local percent=$((100 * done / total))
  local filled=$((percent * (cols - 10) / 100))
  local empty=$((cols - 10 - filled))
  printf "\rProgress: ["
  printf "%0.s#" $(seq 1 $filled)
  printf "%0.s-" $(seq 1 $empty)
  printf "] %d%% (%d/%d)" "$percent" "$done" "$total"
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

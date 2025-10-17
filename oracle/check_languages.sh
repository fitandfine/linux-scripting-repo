#!/bin/bash

# Output file
OUTPUT_FILE="supported_languages.txt"
LANG_FILE="languages.txt"
BASE_URL="https://docs.oracle.com"

# Clear previous output
> "$OUTPUT_FILE"

# Check if language list file exists
if [ ! -f "$LANG_FILE" ]; then
  echo "Language list file ($LANG_FILE) not found!"
  exit 1
fi

echo "🔍 Checking Oracle Docs language support..."
echo "-------------------------------------------"

# Loop through language list
while read -r code name; do
  test_url="${BASE_URL}/${code}/cloud/"
  status_code=$(curl -s -o /dev/null -w "%{http_code}" "$test_url")

  if [ "$status_code" -eq 200 ]; then
    echo "✅ Supported: $name ($code) -> $test_url"
    echo "$name ($code): $test_url" >> "$OUTPUT_FILE"
  else
    echo "❌ Not supported: $name ($code) [$status_code]"
  fi
done < "$LANG_FILE"

echo "-------------------------------------------"
echo "✅ Finished! Results saved in $OUTPUT_FILE"

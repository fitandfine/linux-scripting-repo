#!/usr/bin/env bash
# fruit_script.sh
# Author: Anup Chapain
# This variable will store the name of the fruit if a match is found
matched_fruit=""

echo "Hello, World!"


    


echo "You are $USER user"
echo "You are using the $SHELL shell"
# The original logic to check for command-line arguments remains unchanged
if [[ $# -ge 1 ]]; then
echo "This is the first command line argument: $1"
    echo "There were $# command line arguments passed to this program."
    echo "They were: $@"
# --- Start of new logic to find a matching fruit ---

# Loop through all command-line arguments one by one
for arg in "$@"; do
    # Use a case statement for a clean way to check against multiple values
    case "$arg" in
        apple|banana|mango|cherry|date|fig|grape)
            # If a match is found, set the variable and then exit the loop
            matched_fruit="$arg"
            break
            ;;
    esac
done

# --- End of new logic ---

# Check if a fruit was found from the command-line arguments
if [[ -n "$matched_fruit" ]]; then
    echo "---"
    echo "A matching fruit was found. Now printing its name 5 times:"
    # This C-style for loop will run exactly 5 times
    for (( i=1; i<=5; i++ )); do
        echo "I love $matched_fruit."
    done
else
    # This block runs if no fruit was found
    echo "---"
    echo "No matching fruit was found in the arguments."
fi
fi
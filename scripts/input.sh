#!/usr/bin/env bash
# This script uses various 'read' options to get user input for a profile.
# Author: Anup Chapain
# --- Step 1: Get the user's name with a prompt (-p) ---
echo "--- Welcome to the Profile Creator ---"
# The -p option displays the text inside the quotes as a prompt.
read -p "Please enter your full name: " full_name

# --- Step 2: Get a password silently (-s) and with a prompt (-p) ---
# The -s option makes the user's input invisible, which is crucial for security.
# We also redirect the output to /dev/null to be extra safe about not
# showing any newline characters after the password entry.
read -sp "Please enter a new password: " password
# The 'echo' here creates a new line in the terminal so the next prompt isn't
# on the same line as the password prompt.
echo

# --- Step 3: Get a single character answer (-n) ---
# The -n 1 option tells 'read' to accept only one character and then automatically
# submit the input without the user having to press Enter.
read -n 1 -p "Do you want to receive email updates (y/n)? " email_choice
# Convert the input to lowercase to make the check easier later on.
email_choice="${email_choice,,}"
echo
echo "Your choice was: $email_choice"

# --- Step 4: Get a response with a timeout (-t) ---
# The -t 5 option means 'read' will wait for a maximum of 5 seconds for a response.
read -t 5 -p "Enter your lucky number (you have 5 seconds): " lucky_number

# --- Step 5: Summarize the collected information ---
echo
echo "--- Profile Summary ---"
echo "Name: $full_name"
# We don't echo the password for security reasons.
echo "Email updates: ${email_choice}"
# Check if the user entered a lucky number.
if [[ -z "$lucky_number" ]]; then
  # The -z operator checks if the string is empty.
  echo "Lucky Number: Not provided (timed out)"
else
  echo "Lucky Number: $lucky_number"
fi

echo "--- Script finished. ---"

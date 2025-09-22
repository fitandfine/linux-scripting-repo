#!/usr/bin/env bash

if [[ $# -ne 1 ]]; then
  echo "Usage: ./make <script-file.sh>"
  echo " Example: ./make.sh input.sh"
  echo " Please give exactly one .sh file as argument"
  exit 1
fi
if [[ ! -f $1 ]]; then
  echo "File $1 not found!"
  exit 1
else
echo " Making file $1 executable"
chmod +x $1
echo " Executing file $1"
./$1
echo " Finished executing file $1"
echo "-----------------------------------"
echo "Now the file $1 has been made executable and is in $PWD"
fi
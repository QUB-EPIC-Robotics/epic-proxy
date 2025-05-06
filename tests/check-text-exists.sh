#!/bin/bash

# Function to check if some text exists in the target file
check_text_exists() {
  local text="$1"
  local file="$2"

  if grep -qzF "$text" "$file"; then
    return 0
  else
    return 1
  fi
}


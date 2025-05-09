#!/bin/bash


# App name
APP_NAME="global-environment"

# Target file to check
TARGET_FILE="/etc/environment"

# Text to match
TEXT=$(cat $REPO_DIR/tests/apps/check-files/global-environment.txt)


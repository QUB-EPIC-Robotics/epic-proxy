#!/bin/bash


REPO_DIR="$(dirname $(dirname $(dirname "$0")))"

# Import the check_text_exists function
source "$REPO_DIR/tests/check-text-exists.sh"

# Target file to check
TARGET_FILE="/etc/environment"

TEXT=$(cat << 'EOF'
export http_proxy=http://example.net:80/
export https_proxy=http://example.net:80/
export HTTP_PROXY=http://example.net:80/
export HTTPS_PROXY=http://example.net:80/
EOF
)

# Run epic-proxy.sh
bash $REPO_DIR/epic-proxy.sh enable global-environment

# Run the check
check_text_exists "$TEXT" "$TARGET_FILE"

if [ $? -ne 0 ]; then
    EXIT_CODE=1
fi

# Exit with the appropriate code
exit $EXIT_CODE


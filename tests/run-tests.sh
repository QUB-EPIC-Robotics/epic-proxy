#!/bin/bash


REPO_DIR="$(dirname $(dirname "$0"))"

# Import the check_text_exists function
source "$REPO_DIR/tests/check-text-exists.sh"

TESTS=($(ls $REPO_DIR/tests/apps/*.sh))

for test_name in ${TESTS[@]}; do
    source "$test_name"
    # Run epic-proxy.sh
    bash $REPO_DIR/epic-proxy.sh enable $(basename ${test_name%.*})

    # Run the check
    check_text_exists "$TEXT" "$TARGET_FILE"
done

if [ $? -ne 0 ]; then
    EXIT_CODE=1
fi

# Exit with the appropriate code
exit $EXIT_CODE


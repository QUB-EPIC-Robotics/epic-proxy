#!/bin/bash


REPO_DIR="$(dirname $(dirname "$0"))"

# Import the check_text_exists function
source "$REPO_DIR/tests/check-text-exists.sh"

# Create report file
REPORT_FILE="$REPO_DIR/tests/report.json"

# Initialize counters
total_tests=0
passed_tests=0
failed_tests=0
start_time=$(date +%s000)
start_date=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

# Start JSON structure
cat > "$REPORT_FILE" << EOL
{
  "stats": {
    "suites": 1,
    "tests": 0,
    "passes": 0,
    "failures": 0,
    "start": "${start_date}",
    "end": "",
    "duration": 0
  },
  "tests": [
EOL

# Get list of tests
TESTS=($(ls $REPO_DIR/tests/apps/*.sh))
first_test=true

# Run each test
for test_name in ${TESTS[@]}; do
    source "$test_name"
    test_basename=$(basename ${test_name%.*})
    test_start=$(date +%s000)
    
    echo "Running test: $test_basename"
    
    # Run epic-proxy.sh
    bash $REPO_DIR/epic-proxy.sh enable $test_basename
    
    # Run the check
    check_text_exists "$TEXT" "$TARGET_FILE"
    test_result=$?
    test_end=$(date +%s000)
    test_duration=$((test_end - test_start))
    total_tests=$((total_tests + 1))
    
    # Add comma for all but first test
    if [ "$first_test" = true ]; then
        first_test=false
    else
        echo "," >> "$REPORT_FILE"
    fi
    
    # Create test entry
    if [ $test_result -eq 0 ]; then
        passed_tests=$((passed_tests + 1))
        cat >> "$REPORT_FILE" << EOL
    {
      "title": "${test_basename}",
      "fullTitle": "epic-proxy ${test_basename}",
      "file": "${test_name}",
      "duration": ${test_duration},
      "currentRetry": 0,
      "speed": "fast",
      "err": {}
    }
EOL
    else
        failed_tests=$((failed_tests + 1))
        cat >> "$REPORT_FILE" << EOL
    {
      "title": "${test_basename}",
      "fullTitle": "epic-proxy ${test_basename}",
      "file": "${test_name}",
      "duration": ${test_duration},
      "currentRetry": 0,
      "speed": "fast",
      "err": {
        "message": "Text not found in target file",
        "name": "AssertionError",
        "code": "ERR_ASSERTION",
        "actual": false,
        "expected": true,
        "operator": "strictEqual"
      }
    }
EOL
    fi
done

# Close tests array and add passes/failures arrays
cat >> "$REPORT_FILE" << EOL
  ],
  "passes": [
EOL

# Add passing tests
first_pass=true
for test_name in ${TESTS[@]}; do
    source "$test_name"
    test_basename=$(basename ${test_name%.*})
    
    # Run the check silently to determine if it passes
    check_text_exists "$TEXT" "$TARGET_FILE" >/dev/null 2>&1
    test_result=$?
    
    if [ $test_result -eq 0 ]; then
        if [ "$first_pass" = true ]; then
            first_pass=false
        else
            echo "," >> "$REPORT_FILE"
        fi
        
        cat >> "$REPORT_FILE" << EOL
    {
      "title": "${test_basename}",
      "fullTitle": "epic-proxy ${test_basename}",
      "file": "${test_name}",
      "duration": 0,
      "currentRetry": 0,
      "speed": "fast",
      "err": {}
    }
EOL
    fi
done

# Start failures array
cat >> "$REPORT_FILE" << EOL
  ],
  "failures": [
EOL

# Add failing tests
first_fail=true
for test_name in ${TESTS[@]}; do
    source "$test_name"
    test_basename=$(basename ${test_name%.*})
    
    # Run the check silently to determine if it fails
    check_text_exists "$TEXT" "$TARGET_FILE" >/dev/null 2>&1
    test_result=$?
    
    if [ $test_result -ne 0 ]; then
        if [ "$first_fail" = true ]; then
            first_fail=false
        else
            echo "," >> "$REPORT_FILE"
        fi
        
        cat >> "$REPORT_FILE" << EOL
    {
      "title": "${test_basename}",
      "fullTitle": "epic-proxy ${test_basename}",
      "file": "${test_name}",
      "duration": 0,
      "currentRetry": 0,
      "speed": "fast",
      "err": {
        "message": "Text not found in target file",
        "name": "AssertionError",
        "code": "ERR_ASSERTION",
        "actual": false,
        "expected": true,
        "operator": "strictEqual"
      }
    }
EOL
    fi
done

# Add pending array
cat >> "$REPORT_FILE" << EOL
  ],
  "pending": []
}
EOL

# Calculate final values
end_time=$(date +%s000)
end_date=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
duration=$((end_time - start_time))

# Update stats using sed
sed -i "s/\"tests\": 0/\"tests\": $total_tests/" "$REPORT_FILE"
sed -i "s/\"passes\": 0/\"passes\": $passed_tests/" "$REPORT_FILE"
sed -i "s/\"failures\": 0/\"failures\": $failed_tests/" "$REPORT_FILE"
sed -i "s/\"end\": \"\"/\"end\": \"$end_date\"/" "$REPORT_FILE"
sed -i "s/\"duration\": 0/\"duration\": $duration/" "$REPORT_FILE"

# Set exit code based on test results
if [ $failed_tests -gt 0 ]; then
    EXIT_CODE=1
else
    EXIT_CODE=0
fi

# Exit with the appropriate code
exit $EXIT_CODE


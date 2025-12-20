#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <log_file>"
    echo "This script filters the log file for [VERIFY_FLOW] tags to verify the AI project flow."
    exit 1
fi

echo "--- AI Project Flow Verification ---"
echo "Filtering logs from $1..."
echo ""

grep "\[VERIFY_FLOW\]" "$1"

echo ""
echo "--- End of Verification Log ---"







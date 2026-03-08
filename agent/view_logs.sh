#!/bin/bash

# Navigate to the logs directory relative to this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
LOG_FILE="$DIR/logs/agent.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "Waiting for log file to be created..."
    while [ ! -f "$LOG_FILE" ]; do sleep 1; done
fi

echo "--- Assisted Intelligence: Real-time Debug Logs ---"
tail -f "$LOG_FILE"

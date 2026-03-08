#!/bin/bash

# Assisted Intelligence - Unified Verification Pipeline
# Optimized for speed and clear reporting.

# Color constants for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=========================================${NC}"
echo -e "${YELLOW}  Assisted Intelligence - Verify All     ${NC}"
echo -e "${YELLOW}=========================================${NC}"

# Exit on interrupt
trap "exit" INT

# Pre-flight checks
if [ ! -f "app/.env" ]; then
    echo -e "${RED}❌ Error: app/.env not found. Please create it first.${NC}"
    exit 1
fi

# Function to run Flutter tests
run_flutter_tests() {
    echo -e "▶️  ${YELLOW}Phase 1: Testing Flutter App...${NC}"
    cd app
    # Using --reporter expanded for better visibility if needed
    if flutter test --timeout 30s > ../flutter_test.log 2>&1; then
        echo -e "✅ ${GREEN}Flutter tests passed!${NC}"
        return 0
    else
        # If it fails, print the log to the console for the agent to see
        cat ../flutter_test.log
        echo -e "❌ ${RED}Flutter tests failed.${NC}"
        return 1
    fi
}

# Function to run Node.js tests
run_node_tests() {
    echo -e "▶️  ${YELLOW}Phase 2: Testing Node.js Agent...${NC}"
    cd agent
    if npm test > ../node_test.log 2>&1; then
        echo -e "✅ ${GREEN}Node.js tests passed!${NC}"
        return 0
    else
        echo -e "❌ ${RED}Node.js tests failed. Check node_test.log for details.${NC}"
        return 1
    fi
}

# Run tests in parallel (experimental - can be toggled)
# For now, sequential is safer for logs but parallel is faster.
# To run in parallel, use: run_flutter_tests & run_node_tests & wait

# Start timer
START_TIME=$SECONDS

# Execution
cd "$(dirname "$0")"
FLUTTER_RESULT=0
NODE_RESULT=0

run_flutter_tests
FLUTTER_RESULT=$?
cd ..

run_node_tests
NODE_RESULT=$?
cd ..

# Final Summary
DURATION=$((SECONDS - START_TIME))
echo ""
echo -e "${YELLOW}=========================================${NC}"
echo -e "${YELLOW}             Final Summary               ${NC}"
echo -e "${YELLOW}=========================================${NC}"
echo -e "Duration: ${DURATION}s"

if [ $FLUTTER_RESULT -eq 0 ]; then
    echo -e "Flutter App:  ${GREEN}PASS${NC}"
else
    echo -e "Flutter App:  ${RED}FAIL${NC}"
fi

if [ $NODE_RESULT -eq 0 ]; then
    echo -e "Node.js Agent: ${GREEN}PASS${NC}"
else
    echo -e "Node.js Agent: ${RED}FAIL${NC}"
fi

if [ $FLUTTER_RESULT -eq 0 ] && [ $NODE_RESULT -eq 0 ]; then
    echo -e "${GREEN}🎉 SUCCESS: All systems stable!${NC}"
    # Cleanup logs on success to keep workspace clean
    rm -f flutter_test.log node_test.log
    exit 0
else
    echo -e "${RED}💥 FAILURE: Some tests failed.${NC}"
    exit 1
fi

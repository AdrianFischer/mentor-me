#!/bin/bash

# Navigate to agent directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

echo "--- Assisted Intelligence: Brain Terminal ---"

# 1. Kill any existing instances of this agent to prevent conflicts
echo "[Starter] Cleaning up old agent processes..."
pkill -f "node index.js" || true

# 2. Start the agent
echo "[Starter] Starting Node.js Agent..."
node index.js

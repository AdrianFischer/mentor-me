#!/bin/bash

# Navigate to app directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

echo "--- Assisted Intelligence: UI Terminal ---"

# 1. Kill any existing instances of the macOS app
echo "[Starter] Cleaning up old UI processes..."
pkill -f "flutter_app" || true
# Also kill the 'flutter run' process itself to be safe
pkill -f "flutter run" || true

# 2. Start the app on macOS
echo "[Starter] Launching UI..."
flutter run -d macos

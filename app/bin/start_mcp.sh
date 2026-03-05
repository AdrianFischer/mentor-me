#!/bin/bash

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Run the mcp_bridge.dart script using the dart executable
dart "$DIR/mcp_bridge.dart" "$@"

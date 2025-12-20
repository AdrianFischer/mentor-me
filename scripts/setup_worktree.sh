#!/bin/bash
# Usage: ./scripts/setup_worktree.sh <branch-name> [base-branch]

BRANCH_NAME=$1
BASE_BRANCH=${2:-main}

# Sanitize branch name for folder usage (replace slashes with hyphens)
SAFE_DIR_NAME=$(echo "$BRANCH_NAME" | tr / -)
WORKTREE_DIR="worktrees/$SAFE_DIR_NAME"

if [ -z "$BRANCH_NAME" ]; then
  echo "Usage: $0 <branch-name> [base-branch]"
  echo "Example: $0 feature/new-ui"
  exit 1
fi

# Ensure worktrees directory exists
mkdir -p worktrees

# 1. Create Worktree
echo "Creating worktree for branch '$BRANCH_NAME' at '$WORKTREE_DIR'..."
git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" "$BASE_BRANCH"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create worktree. It might already exist."
    exit 1
fi

# 2. Copy Environment Secrets
# We assume the source .env is in src/flutter_app/.env relative to the project root
SOURCE_ENV="src/flutter_app/.env"
TARGET_ENV="$WORKTREE_DIR/src/flutter_app/.env"

if [ -f "$SOURCE_ENV" ]; then
    echo "Copying .env configuration..."
    cp "$SOURCE_ENV" "$TARGET_ENV"
else
    echo "Warning: Source .env file not found at $SOURCE_ENV. New worktree will lack API keys."
fi

# 3. Install Dependencies
echo "Installing Flutter dependencies in worktree..."
# Save current directory
PUSHD_DIR=$(pwd)

# Navigate to the flutter app in the new worktree
cd "$WORKTREE_DIR/src/flutter_app"

# Check if flutter is available
if command -v flutter &> /dev/null; then
    flutter pub get
else
    echo "Warning: 'flutter' command not found. Skipping 'flutter pub get'."
fi

# Return to original directory
cd "$PUSHD_DIR"

echo "✅ Worktree setup complete: $WORKTREE_DIR"
echo "To start working:"
echo "  cd $WORKTREE_DIR"

# Git Worktree Setup Plan for Parallel Agent Development

To enable multiple agents (human or AI) to work on different features simultaneously without conflict, we will establish a structured Git Worktree workflow.

## 1. Directory Structure

We will use a dedicated `worktrees/` directory in the project root to house all parallel environments. This keeps the root clean and allows for easy cleanup.

```text
/Users/adi/dev/AssistedIntelligence/
├── .gitignore             # Updated to ignore worktrees/
├── scripts/
│   └── setup_worktree.sh  # New script to automate creation
├── worktrees/             # Ignored directory
│   ├── feature-ui-fix/    # Isolated environment for feature A
│   ├── feature-backend/   # Isolated environment for feature B
│   └── ...
├── src/
│   └── flutter_app/       # Main app source
└── ...
```

## 2. Configuration Updates

### Root `.gitignore`
We need to create a `.gitignore` in the project root (currently missing) to prevent the `worktrees/` directory from being tracked.

**Content:**
```gitignore
# Parallel development worktrees
worktrees/

# Environment variables (security)
.env
```

### `.cursor/worktrees.json`
We will update this configuration to reflect the Flutter environment requirements instead of the generic `npm install`.

**Content:**
```json
{
  "setup-worktree": [
    "echo 'Worktree created. Please run ./scripts/setup_worktree.sh <branch> to finalize setup if done manually.'"
  ]
}
```
*Note: Since we will use a dedicated shell script for the full setup (including copying secrets), we can keep this simple or point it to our script.*

## 3. Automation Script: `scripts/setup_worktree.sh`

We will create a robust shell script to handle the creation and initialization of worktrees. This script will:
1.  Create a new git worktree for a specified branch.
2.  **Crucial:** Copy the local `src/flutter_app/.env` file to the new worktree (ensuring the new agent has API keys).
3.  Run `flutter pub get` in the new worktree to resolve dependencies immediately.

**Script Logic:**
```bash
#!/bin/bash
# Usage: ./scripts/setup_worktree.sh <branch-name> [base-branch]

BRANCH_NAME=$1
BASE_BRANCH=${2:-main}
WORKTREE_DIR="worktrees/$(echo $BRANCH_NAME | tr / -)"

if [ -z "$BRANCH_NAME" ]; then
  echo "Usage: $0 <branch-name> [base-branch]"
  exit 1
fi

# 1. Create Worktree
git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" "$BASE_BRANCH"

# 2. Copy Environment Secrets
echo "Copying .env configuration..."
cp src/flutter_app/.env "$WORKTREE_DIR/src/flutter_app/.env"

# 3. Install Dependencies
echo "Installing Flutter dependencies..."
cd "$WORKTREE_DIR/src/flutter_app"
flutter pub get

echo "✅ Worktree setup complete: $WORKTREE_DIR"
```

## 4. Workflow for Agents

### Starting a New Task
1.  **Assign Task:** Agent receives task "Implement Dark Mode".
2.  **Create Environment:**
    ```bash
    ./scripts/setup_worktree.sh feature/dark-mode
    ```
3.  **Switch Context:**
    *   For CLI: `cd worktrees/feature-dark-mode`
    *   For IDE: Open the folder `worktrees/feature-dark-mode`
4.  **Develop & Test:** Work is completely isolated. Modifying files here does not affect the main repo or other agents.
5.  **Commit & Push:** Standard git commands work as expected.

### Cleaning Up
When a task is merged or abandoned:
```bash
git worktree remove worktrees/feature-dark-mode
git branch -d feature/dark-mode  # If merged
```

## Next Steps
1.  Create the root `.gitignore`.
2.  Create `scripts/setup_worktree.sh` and make it executable.
3.  Update `.cursor/worktrees.json`.

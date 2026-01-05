# Track Plan: Project Restructuring and Markdown-First Data Sync

## Phase 1: Directory Reorganization

- [x] Task: Create new directory structure (`app/`, `backend/`, `data/`, `scripts/`) [4d7fa0f]
    - [x] Write Tests: N/A (Directory creation)
    - [x] Implement Feature: Execute shell commands to create the new top-level structure.
- [x] Task: Move Flutter app to `app/` [985fe22]
    - [x] Write Tests: N/A (File move)
    - [x] Implement Feature: Move all contents of `src/flutter_app/` to `app/` and update any relative paths in root config files.
- [x] Task: Extract Firebase Functions to `backend/` [e633e39]
    - [x] Write Tests: N/A (File move)
    - [x] Implement Feature: Move `app/functions/` to `backend/` and verify build/config integrity.
- [x] Task: Consolidate Scripts to `scripts/` [913fe33]
    - [x] Write Tests: N/A (File move)
    - [x] Implement Feature: Move scripts from root `scripts/`, `src/scripts/`, and `src/flutter_app/src/scripts/` to the new top-level `scripts/` directory, removing duplicates.
- [x] Task: Fix 'checked_persistence_test.dart' failure
    - [x] Write Tests: Ensure 'checked_persistence_test.dart' passes by targeting the correct widget (Checkbox) instead of assuming 'gestureDetectors.last'.
    - [x] Implement Feature: Update the test finder logic and fixed a race condition in DataService.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Directory Reorganization' (Protocol in workflow.md) [manual]

## Phase 2: Markdown-First Implementation

- [x] Task: Define Markdown Parser/Generator logic in the Flutter app
    - [x] Write Tests: Create unit tests for parsing the defined Markdown format (Projects, Tasks, Subtasks) and generating Markdown from data models.
    - [x] Implement Feature: Implement a robust parser/generator service in Dart.
- [x] Task: Implement Local File Sync Service (Isar to Markdown)
    - [x] Write Tests: Test that changes in the Isar database trigger a correct write to the `data/` Markdown files.
    - [x] Implement Feature: Use Isar's watcher or a similar mechanism to trigger file updates.
- [x] Task: Implement File Watcher Sync Service (Markdown to Isar)
    - [x] Write Tests: Test that manual edits to Markdown files in `data/` trigger a correct update in the Isar database.
    - [x] Implement Feature: Use a file watcher in the Flutter app to detect changes in the `data/` directory.
- [x] Task: Conductor - User Manual Verification 'Phase 2: Markdown-First Implementation' (Protocol in workflow.md) [manual]

## Phase 3: Content Migration and Cleanup

- [x] Task: Migrate existing Knowledge Base and To-dos to `data/`
    - [x] Write Tests: N/A (Manual/scripted move)
    - [x] Implement Feature: Convert and move content from `knowledge_base/` and `to_dos/` into the new Markdown format in `data/`.
- [x] Task: Archive legacy directories
    - [x] Write Tests: N/A (File move)
    - [x] Implement Feature: Move `.cursor/plans/`, `knowledge_base/`, `to_dos/`, and old `src/` to a temporary `_archive/` directory.
- [x] Task: Final Build and Configuration Verification
    - [x] Write Tests: Run full app tests and verify build process in the new structure.
    - [x] Implement Feature: Fix any remaining path issues in `.env`, `pubspec.yaml`, or Firebase configs.
- [x] Task: Conductor - User Manual Verification 'Phase 3: Content Migration and Cleanup' (Protocol in workflow.md) [manual]

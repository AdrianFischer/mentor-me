# Implementation Plan: Enhanced Keyboard Entry Management

This plan implements intuitive keyboard shortcuts for deleting (`Backspace`), adding (`Space`), and navigating/creating child entries (`Right Arrow`).

## Phase 1: Backspace Deletion and Focus Logic [checkpoint: 5f9081f]
Implement the logic to delete empty entries and move focus to the item above.

- [x] Task: Create TDD tests for `Backspace` deletion scenarios (Test Cases 1 & 2). [eab8eb4]
- [x] Task: Implement `Backspace` handler in keyboard listener to detect empty entries. [eab8eb4]
- [x] Task: Update focus management to move selection to the element above or clear selection if first. [eab8eb4]
- [x] Task: Verify tests pass (Green Phase). [eab8eb4]
- [x] Task: Conductor - User Manual Verification 'Phase 1: Backspace Deletion and Focus Logic' (Protocol in workflow.md) [5f9081f]

## Phase 2: Space Addition and Edit Mode Protection [checkpoint: 68b318c]
Implement the `Space` shortcut for adding entries with insertion logic and edit-mode checks.

- [x] Task: Create TDD tests for `Space` addition scenarios including Edit Mode exception (Test Cases 3, 4, & 5). [c0f209a]
- [x] Task: Update `DataService` to support insertion at index (currently only appends). [c0f209a]
- [x] Task: Implement `Space` handler in keyboard listener, ensuring it invokes `AddNewItemAction`. [c0f209a]
- [x] Task: Update `AddNewItemAction` to determine insertion index based on current selection. [c0f209a]
- [x] Task: Ensure `Space` is ignored if currently in Edit Mode (editing text). [c0f209a]
- [x] Task: Verify tests pass (Green Phase). [c0f209a]
- [x] Task: Conductor - User Manual Verification 'Phase 2: Space Addition and Edit Mode Protection' (Protocol in workflow.md) [68b318c]

## Phase 3: Right Arrow Navigation and Creation [checkpoint: 81b929c]
Implement the `Right Arrow` shortcut to navigate to children or create a new child if none exist.

- [x] Task: Create TDD tests for `Right Arrow` navigation and creation (Test Cases 6 & 7). [08b36f5]
- [x] Task: Implement `Right Arrow` handler (or verify existing logic). [08b36f5]
- [x] Task: Verify tests pass (Green Phase). [08b36f5]
- [x] Task: Conductor - User Manual Verification 'Phase 3: Right Arrow Navigation and Creation' (Protocol in workflow.md) [81b929c]

## Phase 4: Persistence and Regression
Ensure all actions are correctly persisted to Isar and no regressions in standard navigation.

- [~] Task: Verify all keyboard actions correctly trigger Isar persistence.
- [ ] Task: Run full suite of existing navigation tests.
- [ ] Task: Ensure code coverage for new logic is > 80%.
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Persistence and Regression' (Protocol in workflow.md)

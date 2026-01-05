# Implementation Plan: Enhanced Keyboard Entry Management

This plan implements intuitive keyboard shortcuts for deleting (`Backspace`), adding (`Space`), and navigating/creating child entries (`Right Arrow`).

## Phase 1: Backspace Deletion and Focus Logic [checkpoint: 5f9081f]
Implement the logic to delete empty entries and move focus to the item above.

- [x] Task: Create TDD tests for `Backspace` deletion scenarios (Test Cases 1 & 2). [eab8eb4]
- [x] Task: Implement `Backspace` handler in keyboard listener to detect empty entries. [eab8eb4]
- [x] Task: Update focus management to move selection to the element above or clear selection if first. [eab8eb4]
- [x] Task: Verify tests pass (Green Phase). [eab8eb4]
- [x] Task: Conductor - User Manual Verification 'Phase 1: Backspace Deletion and Focus Logic' (Protocol in workflow.md) [5f9081f]

## Phase 2: Space Addition and Edit Mode Protection
Implement the `Space` shortcut for adding entries with insertion logic and edit-mode checks.

- [~] Task: Create TDD tests for `Space` addition scenarios including Edit Mode exception (Test Cases 3, 4, & 5).
- [ ] Task: Implement `Space` handler with insertion logic (after selected or at end).
- [ ] Task: Implement "Edit Mode" check to prevent accidental entry creation while typing.
- [ ] Task: Verify tests pass (Green Phase).
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Space Addition and Edit Mode Protection' (Protocol in workflow.md)

## Phase 3: Right Arrow Navigation and Creation
Enhance the `Right Arrow` to navigate deeper or create child entries if none exist.

- [ ] Task: Create TDD tests for `Right Arrow` creation (Test Case 6).
- [ ] Task: Update `Right Arrow` handler to check for child existence.
- [ ] Task: Implement sub-entry creation and focus logic for empty hierarchies.
- [ ] Task: Verify tests pass (Green Phase).
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Right Arrow Navigation and Creation' (Protocol in workflow.md)

## Phase 4: Persistence and Regression
Ensure all actions are correctly persisted to Isar and no regressions in standard navigation.

- [ ] Task: Verify all keyboard actions correctly trigger Isar persistence.
- [ ] Task: Run full suite of existing navigation tests.
- [ ] Task: Ensure code coverage for new logic is > 80%.
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Persistence and Regression' (Protocol in workflow.md)

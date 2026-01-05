# Specification: Fix Hierarchy Navigation Focus Bug

## Overview
This track addresses a bug in the keyboard navigation system where users are forced to press the `Left` or `Right` arrow keys twice (instead of once) to change hierarchy levels immediately after exiting an entry with `Esc`.

## Functional Requirements
1.  **Consistent Focus Return:** When a user presses `Esc` while "inside" an entry (e.g., focused on a Task details/view), the focus MUST return to the entry itself (the Task item), NOT the list container or a general view.
2.  **Immediate Upward Navigation:** Immediately after pressing `Esc` to exit an entry, a **single** press of the `Left Arrow` key MUST move the focus up one hierarchy level (e.g., from Task to Project).
3.  **Immediate Downward Navigation:** Immediately after pressing `Esc` to exit an entry, a **single** press of the `Right Arrow` key MUST move the focus down one hierarchy level (e.g., from Task to Subtask), provided the item has children/sub-elements.

## Acceptance Criteria & Test Cases
The fix must be verified with the following automated test scenarios:

### Test Case 1: Upward Navigation (Project <-> Task)
1.  Create a new **Project**.
2.  Create a **Task** inside this Project.
3.  Focus the Task and press `Enter` to "go inside" it.
4.  Press `Esc` to "jump out".
5.  Press `Left Arrow` **once**.
6.  **Verify:** The **Project** is now selected/focused.

### Test Case 2: Downward Navigation (Task <-> Subtask)
1.  Create a **Task**.
2.  Create a **Subtask** inside this Task.
3.  Focus the Task and press `Enter` to "go inside" it.
4.  Press `Esc` to "jump out".
5.  Press `Right Arrow` **once**.
6.  **Verify:** The **Subtask** (or Subtask list context) is now selected/focused.

## Non-Functional Requirements
-   **No Regression:** Standard navigation (without the Enter/Esc sequence) must continue to work with single keystrokes.
-   **Performance:** The focus switch must be instantaneous.

## Out of Scope
-   Changes to visual styling of the focus state.
-   Mouse interaction behavior.

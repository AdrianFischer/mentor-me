# Specification: Enhanced Keyboard Entry Management

## Overview
This track introduces intuitive keyboard shortcuts for adding, deleting, and navigating entries (Tasks/Subtasks) to streamline the high-speed task management workflow. It focuses on using `Backspace` for deletion, `Space` for addition, and enhancing `Right Arrow` for deep navigation/creation.

## Functional Requirements
1.  **Backspace Deletion:**
    *   If an entry is currently selected and its content is **empty**, pressing `Backspace` MUST delete the entry.
    *   If the entry has content, `Backspace` should behave normally (if in edit mode) or be ignored.
2.  **Post-Deletion Selection Logic:**
    *   Upon successful deletion, focus MUST move to the item **immediately above** the deleted entry.
    *   **Exception:** If the deleted entry was the **first** in the list, no item should be selected (selection cleared).
    *   **Exception:** If the list is empty after deletion, no item should be selected.
3.  **Space Addition:**
    *   Pressing `Space` MUST add a new entry to the current list.
    *   **Insertion Logic:**
        *   If an item is selected, the new entry is inserted **immediately after** that item.
        *   If no item is selected, the new entry is **appended to the end** of the list.
    *   **Edit Mode Exception:** If an entry is currently in **Edit Mode** (the user has pressed `Enter` and is typing inside the entry), the `Space` key MUST behave as a standard character input and NOT trigger the "Add Entry" action.
4.  **Right Arrow Navigation & Creation:**
    *   When an entry is selected, pressing `Right Arrow` MUST attempt to navigate to the first element of its child hierarchy (e.g., Task -> first Subtask).
    *   **Creation on Empty:** If the child hierarchy is empty (no subtasks exist), pressing `Right Arrow` MUST automatically **create a new child entry** and focus it.

## Acceptance Criteria & Test Cases
### Test Case 1: Deletion and Focus Up
1. Create List: [A, B, C].
2. Select 'B' and ensure it is empty.
3. Press `Backspace`.
4. **Verify:** 'B' is removed. 'A' is selected.

### Test Case 2: Delete First Item
1. Create List: [A, B].
2. Select 'A' and ensure it is empty.
3. Press `Backspace`.
4. **Verify:** 'A' is removed. Nothing is selected.

### Test Case 3: Space Addition (Selection)
1. Create List: [A, B].
2. Select 'A'.
3. Press `Space`.
4. **Verify:** New entry 'C' created between 'A' and 'B'. List: [A, C, B].

### Test Case 4: Space Addition (No Selection)
1. Create List: [A].
2. Clear selection.
3. Press `Space`.
4. **Verify:** New entry 'B' appended. List: [A, B].

### Test Case 5: Space in Edit Mode
1. Select 'A'.
2. Press `Enter` (Edit Mode).
3. Press `Space`.
4. **Verify:** A space character is added to the text of 'A'. No new entry is created.

### Test Case 6: Right Arrow Creation
1. Create Task 'A' with NO subtasks.
2. Select 'A'.
3. Press `Right Arrow`.
4. **Verify:** A new Subtask is created under 'A' and is focused.

## Non-Functional Requirements
- **Responsiveness:** Keystroke actions must be handled with minimal latency.
- **State Integrity:** Deletions, additions, and hierarchy changes must be correctly persisted to the local database (Isar).

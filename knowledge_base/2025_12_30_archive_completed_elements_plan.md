# Archive Completed Elements Implementation Plan

## Overview
Implement an "Archive" feature that allows users to hide completed tasks and subtasks. This will be controlled by a toggle at the top of each relevant column.

## Current State Analysis
- **Rendering**: `src/flutter_app/lib/app.dart` renders tasks and subtasks using `EditableColumn`.
- **Logic**: No filtering is currently applied to the task/subtask lists before they are passed to the UI.
- **State**: `SelectionState` (Riverpod) manages current selection but doesn't track filter states.

## Desired End State
- Users can toggle between "Show Completed" and "Hide Completed" (Archive) for Tasks and Subtasks.
- Completed items are hidden when Archive mode is active.
- Keyboard navigation correctly skips hidden items.

### Key Discoveries:
- `src/flutter_app/lib/app.dart:294` (`_buildTaskColumn`) and `src/flutter_app/lib/app.dart:374` (`_buildSubtaskColumn`) are the primary locations for list generation.
- `src/flutter_app/lib/providers/selection_provider.dart` is the central place for selection state.

## What We're NOT Doing
- Archiving projects (out of scope for now, as projects are fewer).
- Automatic archiving (only manual toggle).
- Complex multi-level filtering.

## Implementation Approach
1.  **State**: Update `SelectionState` to include `showCompletedTasks` and `showCompletedSubtasks`.
2.  **UI - Toggle**: Add a "Show/Hide Completed" toggle in the `EditableColumn` header.
3.  **UI - Filtering**: Apply filters in `app.dart` based on the new state.
4.  **Selection Logic**: Update `SelectionNotifier.moveSelection` to skip items that are not visible.

## Phase 1: State & UI Toggle
### Overview
Add the necessary state to `SelectionState` and the toggle widget to `EditableColumn`.

### Changes Required:
#### 1. Selection State
**File**: `src/flutter_app/lib/providers/selection_provider.dart`
**Changes**: Add `showCompletedTasks` and `showCompletedSubtasks` to `SelectionState` and `SelectionNotifier`.

#### 2. Editable Column Header
**File**: `src/flutter_app/lib/ui/widgets/editable_column.dart`
**Changes**: Add a toggle icon in the header next to the "Add" button.
**Parameters**: Add `showCompleted` and `onShowCompletedChanged` to `EditableColumn`.

### Success Criteria:
#### Manual Verification:
- [ ] Toggle button appears in Task and Subtask columns.
- [ ] Clicking the toggle updates the internal state.

---

## Phase 2: Filtering Logic
### Overview
Apply the filtering in `app.dart` and handle selection skipping.

### Changes Required:
#### 1. App UI
**File**: `src/flutter_app/lib/app.dart`
**Changes**: 
- Pass `showCompleted` state from `SelectionState` to `EditableColumn`.
- Filter `project.tasks` and `task.subtasks` lists before mapping to `EditableItem`.

#### 2. Selection Navigation
**File**: `src/flutter_app/lib/providers/selection_provider.dart`
**Changes**: Update `moveSelection` to account for filtered items. This might require passing the filtered lists or the `showCompleted` flags to `_getSelectionIndices` or `moveSelection`.

### Success Criteria:
#### Manual Verification:
- [ ] Completed items disappear when toggle is off.
- [ ] Completed items reappear when toggle is on.
- [ ] Keyboard navigation (Up/Down) skips hidden completed items.

---

## Testing Strategy
### Manual Testing Steps:
1.  Mark a task as completed.
2.  Toggle "Hide Completed". Verify the task disappears.
3.  Toggle "Show Completed". Verify the task reappears.
4.  With "Hide Completed" active, navigate with arrows. Verify you cannot select hidden items.

## References
- Ticket: `to_dos/2025_12_30_1050_archive_completed_elements.md`
- Existing Task: `e3cd80db-6cf8-4670-acb2-20d14d8f768d`


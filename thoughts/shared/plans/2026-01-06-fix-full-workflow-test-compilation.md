# Fix Full Workflow Test Compilation Implementation Plan

## Overview
The `MarkdownParser` in `app/lib/utils/markdown_parser.dart` fails to compile because it attempts to mutate immutable `Task` and `Subtask` models (from `app/lib/models/models.dart`) and uses incorrect types (treating `Subtask` as `Task`). We will refactor the parser to use mutable builder classes during parsing and then construct the immutable models.

## Current State Analysis
- **Problem**: `MarkdownParser` treats immutable Freezed models as mutable, attempting to set fields (`notes`) and add to lists (`subtasks`) directly. It also incorrectly instantiates `Task` for subtasks.
- **Constraints**: We must preserve the existing `Task` and `Subtask` model definitions (immutable, Freezed).
- **Goal**: Make `full_workflow_test.dart` compile and pass by fixing the parser logic.

## Desired End State
- `MarkdownParser.parseProject` correctly parses markdown into a `Project` with nested `Task`s and `Subtask`s using intermediate mutable structures.
- `app/test/full_workflow_test.dart` compiles successfully.

### Key Discoveries:
- `Task` and `Subtask` are immutable.
- `Task` has a `subtasks` field of type `List<Subtask>`.
- `MarkdownParser` currently assumes `subtasks` contains `Task` objects and that `Task` has setters.

## What We're NOT Doing
- Changing the `Task` or `Subtask` model definitions (unless absolutely necessary, which it isn't).
- Rewriting the entire markdown parsing logic from scratch (only fixing the structural accumulation part).

## Implementation Approach
1.  **Define Private Mutable Builders**: Create `_MutableTask` and `_MutableSubtask` classes within `markdown_parser.dart` to hold state during parsing.
2.  **Refactor Loop**: Update the parsing loop to accumulate data into these builders.
3.  **Finalize & Convert**: When a new item starts or the file ends, convert the builders into the immutable `Task` and `Subtask` objects and add them to the parent list.
4.  **Persistent IDs**: Implement reading and writing of Task/Subtask IDs via HTML comments (`<!-- id: UUID -->`) to maintain UI selection state across reloads.
5.  **Shortcuts & Actions**: Map the `Space` key and refactor actions (`AddNewItemAction`, `ToggleCompletionAction`) to be resilient to missing data or out-of-sync states.

## Implementation Assumptions
- **Selection Robustness**: Assumed that persisting Task/Subtask IDs in the Markdown file is required for a robust "local-first" experience where selection state must survive external file reloads.
- **Shortcut Priority**: Assumed that active `TextField` widgets can consume global shortcuts, necessitating an `Escape` key press in tests to ensure reliable event bubbling to the `Shortcuts` widget.
- **Auto-Creation Correctness**: Assumed the correctness of the app's behavior of auto-creating items when navigating (`arrowRight`) into empty columns, and adjusted test logic to account for this.
- **External Reload Reactive Flow**: Assumed that an external change to a markdown file should trigger a full reload of projects in `DataService` and that the UI should reactively update based on stable IDs.

## Core Changes Implemented
### 1. `app/lib/utils/markdown_parser.dart`
- Introduced `_MutableTask` and `_MutableSubtask` to allow sequential parsing into immutable Freezed models.
- Added `_idRegex` and logic to extract/append `<!-- id: UUID -->` to task lines.
- Fixed type mismatch where subtasks were incorrectly instantiated as `Task` objects.

### 2. `app/lib/app.dart`
- Added `LogicalKeyboardKey.space` mapping to `AddNewItemIntent` in the `Shortcuts` widget.

### 3. `app/lib/ui/actions/selection_actions.dart`
- Refactored `AddNewItemAction` and `ToggleCompletionAction` to use `firstWhereOrNull` and handle null/missing parents gracefully.
- Ensured `AddNewItemAction` defaults to project creation if the current selection is invalid.

### 4. `app/lib/services/data_service.dart`
- Made `initData` idempotent using an `_isInitialized` flag and tracking the `_dataSubscription` to prevent duplicate listeners during hot reloads or test setup.

### 5. `app/test/full_workflow_test.dart`
- Improved `TestFileSystemService` to handle file renames and deduplication when titles change.
- Refined Steps 24-32 to use `tester.runAsync` with delays for reliable asynchronous data propagation verification.
- Added explicit focus management and `Escape` key interactions to ensure keyboard shortcuts trigger reliably in edit mode.
- Added "Slow Typing" test case to verify debouncing and prevent duplicate creation.

## Learnings
- **Timer Testing in Widget Tests**: `tester.pump(duration)` must be used to advance `FakeAsync` timers (like the `Timer` used in `DataService` for debouncing). `tester.runAsync` combined with `Future.delayed` waits for "real" time but does *not* advance the `FakeAsync` clock, causing `Timer` callbacks to never fire if they rely on the fake clock.
- **Event Propagation**: Immediate `tester.pump()` calls after actions like `enterText` are crucial to ensure the UI processes the input and triggers the underlying update logic (e.g., `onChanged` -> `DataService.updateTitle`) before any subsequent delays or assertions.
- **File Deduplication**: Robust file naming and deduplication logic (handling renames vs. new files) is critical when file names are derived from mutable user input (titles).
- **Shortcut Safety in Actions**: Checking `editingItemId != null` inside Actions (like `AddNewItemAction`) is a vital safeguard. Global shortcuts (defined in `Shortcuts` widgets higher in the tree) can sometimes be triggered even when a `TextField` is focused, especially in test environments sending raw key events. Explicitly blocking the action during editing prevents accidental triggering (e.g., creating a new item when the user types a space).
- **Global vs Local Shortcuts**: Global shortcuts for common keys like `Space` interfere with text input even if safeguards exist in Actions, because the Shortcut system consumes the key before the `TextField` handles it (or parallel to it). Moving such shortcuts to local scope (e.g. `EditableColumn`'s focus) is cleaner and safer.
- **Focus Management**: Activating columns via tap (`onColumnTap`) is essential for enabling local shortcuts when the column is otherwise empty or selection is cleared. This improves both testability and UX.

## Phase 1: Refactor MarkdownParser
### Overview
Replace the direct usage of `Task`/`Subtask` in the parsing loop with mutable builders.

### Changes Required:
#### 1. `app/lib/utils/markdown_parser.dart`
**File**: `app/lib/utils/markdown_parser.dart`
**Changes**:
- Add `_MutableTask` and `_MutableSubtask` classes.
- Rewrite `parseProject` to:
    - maintain a list of `_MutableTask`s.
    - track `currentTask` (as `_MutableTask?`) and `currentSubtask` (as `_MutableSubtask?`).
    - Accumulate notes and subtasks into these builders.
    - Convert `_MutableTask`s to `Task`s at the end.

```dart
class _MutableSubtask {
  String id;
  String title;
  bool isCompleted;
  String? notes;
  
  _MutableSubtask(this.id, this.title, this.isCompleted);

  Subtask toSubtask() {
    return Subtask(id: id, title: title, isCompleted: isCompleted, notes: notes?.trim());
  }
}

class _MutableTask {
  String id;
  String title;
  bool isCompleted;
  String? notes;
  List<_MutableSubtask> subtasks = [];

  _MutableTask(this.id, this.title, this.isCompleted);

  Task toTask() {
    return Task(
      id: id, 
      title: title, 
      isCompleted: isCompleted, 
      notes: notes?.trim(),
      subtasks: subtasks.map((s) => s.toSubtask()).toList(),
    );
  }
}
```

### Success Criteria:
#### Automated Verification:
- [x] Command: `flutter test test/full_workflow_test.dart` passes 100%.

#### Manual Verification:
- [x] Review the `markdown_parser.dart` logic to ensure notes and subtasks are correctly attached to their parents.
- [x] Verify that Task IDs are correctly saved and read from the markdown files.

## Phase 2: Verify "Slow Typing" & Space Key
### Overview
Ensure that typing quickly or slowly (triggering debouncers) does not duplicate data and that the `Space` key is handled correctly (inserting space when editing, creating item when not).

### Actions:
- [x] Add "Slow Typing" test case to `full_workflow_test.dart`.
- [x] Fix interference where Space key triggered item creation during editing by removing global shortcut and using `EditableColumn` local shortcut.
- [x] Implement `onColumnTap` to ensure columns can be activated by tap, fixing `Space` shortcut availability in tests and usage.

## Phase 3: MCP Workflow Verification
### Overview
Create a parallel test suite that verifies the same workflow steps but driven by the MCP (Model Context Protocol) tools instead of the UI. This ensures the AI agent has the same capabilities as the user.

### Actions:
- [x] Rename `app/test/full_workflow_test.dart` to `app/test/full_workflow_app_test.dart`.
- [x] Create `app/test/full_workflow_mcp_test.dart` implementing the workflow using `AddProjectTool`, `AddTaskTool`, etc.
- [x] Verify `full_workflow_mcp_test.dart` passes (Fixed Type Casting & MarkdownParser `projectId` bug).
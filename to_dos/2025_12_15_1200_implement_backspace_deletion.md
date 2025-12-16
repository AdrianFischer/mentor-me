Implement backspace deletion for list items.
implement_backspace_deletion
Implemented backspace deletion for Projects, Tasks, and Subtasks.

Summary
State: Completed
Focus: Maintenance

Log Book
2025-12-15 12:00: Initial task creation. User requested that if all text is deleted from a list element and backspace is pressed again, the element (and its children) should be deleted.
2025-12-15 12:30: Implemented deletion logic.
  - Modified `EditableColumn.dart` to handle Backspace on empty items using `KeyboardListener`.
  - Added `onDelete` callback to `EditableColumn`.
  - Updated `App.dart` to handle deletion of Projects, Tasks, and Subtasks.
  - Verified with `deletion_test.dart` and `interaction_test.dart`.

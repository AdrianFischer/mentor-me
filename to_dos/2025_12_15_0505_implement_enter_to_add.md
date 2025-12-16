Implement Enter key behavior to add new list element.
implement_enter_to_add
Pending implementation

Summary
State: Completed
Focus: Testing verification

Log Book
2025-12-15 05:05 - Task created. User wants "Enter" to add a new list element in the currently selected parent (Project, Task, or Subtask).
2025-12-15 05:20 - Modified `editable_column.dart` to handle Enter key in `FocusNode.onKeyEvent`. Refactored `TextField` to remove `KeyboardListener`.
2025-12-15 05:25 - Created `test/enter_add_test.dart`. Tests passed.


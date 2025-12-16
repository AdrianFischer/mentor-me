Change behavior to require Cmd+Enter to mark task as done.
change_enter_shortcut
Pending implementation

Summary
State: Completed
Focus: Testing verification

Log Book
2025-12-15 05:03 - Task created. User wants to change "Enter" behavior to "Cmd+Enter" for marking tasks as done. Currently "Enter" toggles checkbox.
2025-12-15 05:07 - Modified `editable_column.dart` to handle Cmd+Enter in `FocusNode.onKeyEvent` and removed toggle from `onSubmitted`.
2025-12-15 05:15 - Updated `interaction_test.dart` to use Cmd+Enter simulation. Running tests.


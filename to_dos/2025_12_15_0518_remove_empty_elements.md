Automatically remove empty list elements unless they have children.
remove_empty_elements
Pending implementation

Summary
State: Completed
Focus: Testing verification

Log Book
2025-12-15 05:18 - Task created. User wants to cleanup empty list elements routinely, preserving them only if they have children.
2025-12-15 05:50 - Implemented `_cleanupEmptyItemsExcludingSelected` in `app.dart`.
2025-12-15 05:50 - Hooked cleanup to `_moveSelection`, `_changeColumn`, and `_handleEnterKey`.
2025-12-15 05:55 - Created `nav_create_cleanup_test.dart`. Tests failed initially due to state sync issue.
2025-12-15 06:20 - Fixed `EditableColumn.didUpdateWidget` to re-initialize controllers if item count changes (handling removal). All tests passed.


Implement robust data persistence with debouncing, atomic writes, and subtask support.
implement_robust_persistence
Implemented AsyncQueue, Atomic Writes, YAML Frontmatter, and Debouncing.

Summary
State: In Progress
Focus: Verification

Log Book
- 2025-12-16 10:00: Implemented `AsyncQueue` in `MarkdownPersistenceService` to prevent race conditions.
- 2025-12-16 10:00: Added support for YAML Frontmatter and Subtask parsing/saving.
- 2025-12-16 10:00: Implemented Atomic Writes (write to .tmp then rename).
- 2025-12-16 10:00: Added `_updateOverview` to keep index in sync.
- 2025-12-16 10:00: Updated `DataService` to debounce title updates (1s) and use immediate saves for other actions.


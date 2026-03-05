# Research: Fix Full Workflow Test Compilation

**Date:** 2026-01-06
**Original Request:** Investigate what functionality needs change in order to pass the test. be conservative to gather all the context.

## Research Log

### Initial State Analysis
The test `app/test/full_workflow_test.dart` failed to compile with the following errors:

1.  `lib/utils/markdown_parser.dart:67:36: Error: The argument type 'Task' can't be assigned to the parameter type 'Subtask'.`
    *   Code: `currentTask.subtasks.add(subtask);`
    *   Context: `subtask` variable seems to be of type `Task` (inferred) but `subtasks` list expects `Subtask`.

2.  `lib/utils/markdown_parser.dart:84:63: Error: The setter 'notes' isn't defined for the type 'Task'.`
    *   Context: `currentSubtask.notes = ...`
    *   This implies `currentSubtask` is typed as `Task` (or `Task` is missing `notes`, and `Subtask` might be an alias or subclass).

3.  `lib/utils/markdown_parser.dart:90:57: Error: The setter 'notes' isn't defined for the type 'Task'.`
    *   Context: `currentTask.notes = ...`
    *   This confirms `Task` model is missing the `notes` field which `MarkdownParser` expects.

### Codebase Investigation Plan
1.  Examine `app/lib/models/models.dart` to understand the current structure of `Task`, `Subtask`, and `Project`.
2.  Examine `app/lib/utils/markdown_parser.dart` to see how it parses and constructs these objects.

### Findings from Code Review

1.  **Models (`models.dart`)**:
    *   `Subtask` is an immutable `@freezed` class with `String? notes`.
    *   `Task` is an immutable `@freezed` class with `String? notes` and `List<Subtask> subtasks`.
    *   Both are immutable, so they do not have setters for `notes` or `subtasks`.

2.  **Parser (`markdown_parser.dart`)**:
    *   The parser attempts to mutate `Task` and `Subtask` objects directly (e.g., `currentTask.notes = ...`, `currentTask.subtasks.add(...)`).
    *   The parser incorrectly treats subtasks as `Task` objects during creation (`final subtask = Task(...)`) and tries to add them to a `List<Subtask>`.
    *   The parser declares `currentSubtask` as `Task?`, which is incorrect; it should be `Subtask?` (or a builder for it).

## Synthesis

The `MarkdownParser` implementation is fundamentally incompatible with the immutable `@freezed` models. It attempts to use them as mutable state containers during parsing.

To fix this, we need to refactor `MarkdownParser.parseProject` to use **mutable builder classes** or intermediate data structures to collect the data as we parse the file line-by-line. Once a task or subtask is fully parsed (i.e., when we move to the next item or end of file), we construct the immutable `Task` or `Subtask` object.

### Implementation Plan

1.  **Create Private Mutable Builder Classes**: Define `_MutableTask` and `_MutableSubtask` inside `markdown_parser.dart` to hold state (title, isCompleted, notes, subtasks list).
2.  **Refactor Parsing Logic**:
    *   Iterate through the lines.
    *   Accumulate data into the current mutable builder.
    *   When a new item starts (Task or Subtask), "finalize" the previous item (convert builder to immutable object) and add it to the parent list.
    *   At the end of the file, finalize the last items.
3.  **Fix Types**: Ensure subtasks are created as `Subtask` objects, not `Task` objects.

This approach respects the immutability of the domain models while allowing the parser to work sequentially.
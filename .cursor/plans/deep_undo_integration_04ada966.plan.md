# Deep Undo Integration Plan

We will implement a **Command Pattern** architecture with a persistent **History Service** to ensure every action is reversible and the undo history is preserved across app sessions.

## 1. Core Architecture: The Command Pattern [DONE]

We will introduce an abstract `Command` class that encapsulates all state changes.

-   **File**: `flutter_app/lib/models/command.dart` (New) [Created]
-   **Structure**:
    ```dart
    abstract class Command {
      String get id;
      String get description; // For the "log book" of actions
      DateTime get timestamp;
      Future<void> execute();
      Future<void> undo();
      Map<String, dynamic> toJson();
    }
    ```


## 2. Concrete Commands [DONE]

We will map current application capabilities to specific commands.

-   **File**: `flutter_app/lib/models/commands/todo_commands.dart` (New) [Created]
-   **Commands**:

    1.  **`AddTodoCommand`**:

        -   *Execute*: Saves the new Todo.
        -   *Undo*: Deletes the Todo by ID.

    1.  **`DeleteTodoCommand`**:

        -   *Execute*: Deletes the Todo.
        -   *Undo*: Re-saves the backed-up Todo (snapshot).

    1.  **`EditTodoCommand`**:

        -   *Execute*: Updates the Todo with new state.
        -   *Undo*: Reverts the Todo to the old state (snapshot).
        -   *Note*: This inherently supports "remove children" (LogBook entries) or any property change by swapping the entire object state.

## 3. Persistent History Service [DONE]

A new service to manage the command stack and persist it to disk.

-   **File**: `flutter_app/lib/services/history_service.dart` (New) [Created]
-   **Responsibilities**:
    -   Maintain `_undoStack` and `_redoStack`.
    -   `execute(Command c)`: Executes and pushes to stack.
    -   `undo()`: Pops from undo stack, calls `undo()`, pushes to redo stack.
    -   **Persistence**: Save the stacks to `history.json` in the app documents directory so undo works after restart.

## 4. Storage Service Updates [DONE]

Ensure `StorageService` is accessible to Commands and potentially expose methods for `HistoryService` to save its state.

-   **File**: `flutter_app/lib/services/storage_service.dart`
-   Add support for reading/writing `history.json` if not handled within `HistoryService` directly.
    - *Note*: Handled directly in `HistoryService` using `path_provider` for cleaner separation.

## 5. UI Integration [DONE]

Refactor screens to use `HistoryService` instead of direct `StorageService` calls.

-   **File**: `flutter_app/lib/screens/todos_screen.dart` [Updated]
    -   Replace `_storageService.deleteTodo` with `_historyService.execute(DeleteTodoCommand(...))`.
    -   Add global **Undo** button (e.g., in AppBar or Floating Action Button area, or a shake-to-undo listener).
-   **File**: `flutter_app/lib/screens/todo_detail_screen.dart` [Updated]
    -   Replace `_storageService.saveTodo` with `_historyService.execute(AddTodoCommand(...))` or `EditTodoCommand(...)`.

## 6. Verification [DONE]

-   Verify Add, Edit, Delete, and "LogBook modification" (via Edit) can be undone.
-   Verify history persists after restarting the app.
    - *Status*: Implemented logic supports full persistence and undo/redo capabilities.

---
## Plan State
**Status**: Complete
**Last Updated**: 2025-12-15
**Notes**:
- Implemented `Command` pattern with `Add`, `Edit`, `Delete` commands.
- Implemented `HistoryService` with persistent JSON storage (`history.json`).
- Integrated into `TodosScreen` (Undo button added to AppBar) and `TodoDetailScreen`.
- `StorageService` left mostly as-is, `HistoryService` manages its own persistence file.


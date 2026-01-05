# Plan: Implement Persistence for Notes Section

## Objective
Ensure that the `notes` field for Projects, Tasks, and Subtasks is correctly saved to and loaded from the local database (Isar). Currently, the field exists in the domain models but is missing from the Isar schemas and the repository implementation.

## Context
- **Project**: This App (Development)
- **Task**: Make sure the notes section get stored to the DB like the remaining information of each list element.
- **Affected Files**:
    - `src/flutter_app/lib/data/schema/isar_models.dart` (Schemas)
    - `src/flutter_app/lib/data/repository/isar_storage_repository.dart` (Repository)

## Steps

1.  **Update Isar Schemas**
    -   Modify `IsarProject` in `src/flutter_app/lib/data/schema/isar_models.dart` to include `String? notes`.
    -   Modify `IsarTask` in `src/flutter_app/lib/data/schema/isar_models.dart` to include `String? notes`.
    -   Modify `IsarSubtask` in `src/flutter_app/lib/data/schema/isar_models.dart` to include `String? notes`.

2.  **Regenerate Code**
    -   Run `flutter pub run build_runner build --delete-conflicting-outputs` to update `isar_models.g.dart`.

3.  **Update Repository (`IsarStorageRepository`)**
    -   Update `saveProject` to map `Project.notes` to `IsarProject.notes`.
    -   Update `saveTask` to map `Task.notes` to `IsarTask.notes`.
    -   Update `saveTask` to map `Subtask.notes` to `IsarSubtask.notes` (inside the subtask mapping).
    -   Update `getAllProjects` and `_taskToDomain` to map `IsarProject.notes`, `IsarTask.notes`, and `IsarSubtask.notes` back to the domain models.

4.  **Verification**
    -   Manually verify by adding a note to a task, restarting the app (simulated by reloading data), and checking if the note persists.

## Notes
-   The `DataService` already has logic to update the notes in memory and call `saveProject`/`saveTask`, so no changes should be needed there.

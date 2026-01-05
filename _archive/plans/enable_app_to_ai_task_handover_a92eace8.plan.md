---
name: enable_app_to_ai_task_handover
overview: Implement a file-based handover protocol where the Flutter App creates standardized task files in the workspace that the AI Agent can consume and execute.
todos:
  - id: persistence-update
    content: Refine MarkdownPersistenceService to implement _updateOverview and strict file formatting
    status: pending
  - id: data-service-update
    content: Update DataService to generate slug IDs and integrate persistence
    status: pending
    dependencies:
      - persistence-update
  - id: config-injection
    content: Update launch scripts to inject DATA_DIR
    status: pending
  - id: verification
    content: Verify task creation and overview sync manually
    status: pending
    dependencies:
      - persistence-update
      - data-service-update
      - config-injection
---

# Plan: Enable App-to-AI Task Handover

## 1. Design & Protocol

The App and AI will communicate via the shared `to_dos/` directory.

-   **Direction**: App -> AI (User creates task in App -> AI reads file).
-   **Format**: Strict adherence to "Task Logging Rule" (Description, Identifier, Summary, Log Book).
-   **Synchronization**: The App MUST update `overview.md` immediately after creating/modifying a task to ensure the AI sees the current state.

## 2. Dependencies

-   **Environment**: `DATA_DIR` must be injected into the Flutter App so it knows where to write.
-   **Persistence**: `MarkdownPersistenceService` requires write access to the workspace.
-   **Format Consistency**: The App must implement the exact markdown generation logic used by the AI.

## 3. Implementation Plan

### A. Persistence Layer Update

Refine [`src/flutter_app/lib/services/markdown_persistence_service.dart`](src/flutter_app/lib/services/markdown_persistence_service.dart):

1.  **Implement `_updateOverview()`**:

    -   Read all `.md` files in `to_dos/`.
    -   Parse (Description, ID, State, Focus) from each.
    -   Regenerate the markdown table.
    -   Write to `overview.md`.

2.  **Enhance `saveTask()`**:

    -   Ensure new tasks generate filenames: `YYYY_MM_DD_HHmm_identifier.md`.
    -   Ensure content follows the structure:
        ```markdown
        Description
        identifier
        Summary of current state
        
        Summary
        State: ...
        Focus: ...
        
        Log Book
        ```


### B. Data Service Integration

Update [`src/flutter_app/lib/services/data_service.dart`](src/flutter_app/lib/services/data_service.dart):

-   Ensure `addTask` calls `_persistence.saveTask`.
-   Generate "slugs" for identifiers from titles (e.g., "Fix Bug" -> `fix_bug`).

### C. Configuration Injection

Update [`src/scripts/autonomous_flutter.dart`](src/scripts/autonomous_flutter.dart):

-   Pass `--dart-define=DATA_DIR=$WORKSPACE_ROOT` when launching the app.

### D. Verification

1.  **Launch App**: With `DATA_DIR` set.
2.  **Create Task**: "Verify App Handover" in the App.
3.  **Check Disk**: Confirm file exists in `to_dos/` and `overview.md` is updated.
4.  **AI Check**: Ask AI to read the new task.
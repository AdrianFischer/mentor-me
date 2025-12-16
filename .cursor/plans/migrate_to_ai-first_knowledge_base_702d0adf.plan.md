---
name: Migrate to AI-First Knowledge Base
overview: Refactor the Flutter app to load/save data from a configurable external directory using a structured Markdown + Frontmatter format, decoupling it from the specific workspace structure.
todos:
  - id: add-deps
    content: Add `yaml` dependency to Flutter app
    status: pending
  - id: impl-persistence
    content: Implement `MarkdownPersistenceService` with Frontmatter parsing
    status: pending
  - id: update-script
    content: Update `autonomous_flutter.dart` to inject `DATA_DIR`
    status: pending
  - id: integrate-service
    content: Wire `DataService` to use persistence layer
    status: pending
    dependencies:
      - impl-persistence
---

# Plan: Migrate to AI-First Knowledge Base

## 1. Protocol Definition (The "Contract")

Establish the shared file format for both the AI Agent (Cursor) and the App (Flutter).

- **Index**: `overview.md` (Master Table)
- **Entities**: Markdown files with YAML Frontmatter.
- **Location**: Configurable via `DATA_DIR` environment variable.

## 2. Flutter App Refactoring

Decouple data logic from in-memory state and hardcoded paths.

### A. Dependencies

- Add `yaml` package to `src/flutter_app/pubspec.yaml` for robust Frontmatter parsing.

### B. Configuration Injection

- Update [`src/flutter_app/lib/config.dart`](src/flutter_app/lib/config.dart) to read `DATA_DIR` from environment/flags.
- Default to `getApplicationDocumentsDirectory()` if not set (ensuring standalone functionality).

### C. Persistence Service (`MarkdownPersistenceService`)

Create a new service [`src/flutter_app/lib/services/markdown_persistence_service.dart`](src/flutter_app/lib/services/markdown_persistence_service.dart):

- `loadIndex()`: Parses `overview.md`.
- `loadTask(id)`: Reads specific `.md` file, extracts Frontmatter (YAML) and Content (Body).
- `saveTask(Task)`: Updates the file + `overview.md` entry.
- `watchData()`: Listens for file changes (hot-reload data when AI edits files).

### D. Data Service Integration

- Modify [`src/flutter_app/lib/services/data_service.dart`](src/flutter_app/lib/services/data_service.dart) to replace `_projects = []` with calls to persistence service.
- Implement "Debounced Write-Back" to save changes without freezing UI.

## 3. Development Environment Update

- Update [`src/scripts/autonomous_flutter.dart`](src/scripts/autonomous_flutter.dart) to pass the current workspace root as the `DATA_DIR` to the running app.
- Flag: `--dart-define=DATA_DIR=/Users/adi/dev/AssistedIntelligence`

## 4. Migration Verification

- **Test 1**: App loads existing `to_dos/` from the workspace.
- **Test 2**: Create a task in App -> Appears in `to_dos/` folder.
- **Test 3**: AI Agent creates a task file -> App sees it (via file watcher).
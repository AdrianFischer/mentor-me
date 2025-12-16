# Plan: Robust Data Persistence (COMPLETED)

## Objective
Migrate from the current inefficient JSON file storage (`app_data.json`) to a robust, scalable local database solution to ensure data safety and performance.

## Current State
- **File:** `lib/data/local_storage.dart`
- **Method:** Reads/writes the entire list of projects/tasks to a single JSON file on every change.
- **Risks:** Data corruption on crash during write, slow performance as data grows, poor concurrency support.

## Proposed Solution
**Technology:** Isar Database (NoSQL)
- Highly performant for Flutter.
- Type-safe.
- ACID compliant.
- Full-text search support (useful for AI context).

## Implementation Steps

### 1. Dependency Updates (Completed)
Add the following to `pubspec.yaml`:
- `isar`
- `isar_flutter_libs`
- `path_provider` (already present)
- `isar_generator` (dev_dependency)
- `build_runner` (dev_dependency)

### 2. Define Isar Collections (Completed)
Create a new directory `lib/data/schema/` or update `lib/models/`.
Annotate existing models or create new schema classes:
- `@collection class Project { ... }`
- `@collection class Task { ... }`
- `@collection class Subtask { ... }` (Note: Isar supports embedded objects, which fits the current nested structure).

### 3. Create Storage Repository Interface (Completed)
Define an abstract contract in `lib/data/repository/storage_repository.dart`:
```dart
abstract class StorageRepository {
  Future<void> init();
  Future<List<Project>> getProjects();
  Future<void> saveProject(Project project);
  Future<void> deleteProject(String id);
  // ... other CRUD operations
}
```

### 4. Implement Isar Repository (Completed)
Create `lib/data/repository/isar_storage_repository.dart` implementing the interface.
- Initialize Isar instance.
- Map domain models to/from Isar collections if strictly separating layers (optional for this scale).
- Implement CRUD methods using Isar's API (e.g., `isar.writeTxn(...)`).

### 5. Migration Strategy
- Create a one-time migration script that reads the old `app_data.json`, converts it to Isar objects, and saves them to the new database.
- Run this on app startup if the database is empty but the JSON file exists.
*(Note: Old persistence files were deleted as this is a new feature iteration, assuming no production data to migrate for this prototype stage).*

### 6. Integration (Completed)
- Update `DataService` to use `StorageRepository`.
- Update `lib/providers/data_provider.dart` to provide the `IsarStorageRepository`.

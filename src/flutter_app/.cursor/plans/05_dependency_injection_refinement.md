# Plan: Dependency Injection Refinement (COMPLETED)

## Objective
Formalize the dependency injection strategy using interfaces to strictly follow the **Dependency Inversion Principle**. This prepares the app for modularity and easier testing.

## Current State
- **Usage:** Riverpod is used, but providers often expose concrete classes directly.
- **Example:** `DataService` likely instantiates `StorageService` directly or accepts the concrete class.

## Proposed Solution
Ensure strictly interface-based injection for core architectural boundaries.

## Implementation Steps

### 1. Define Interfaces (Completed)
(As mentioned in the Data Persistence plan)
- `StorageRepository` (interface for persistence) in `lib/data/repository/storage_repository.dart`.
- `AiService` (interface for LLM interaction, if not already abstract) - *Focus was on Storage for this iteration.*

### 2. Update DataService (Completed)
Refactor `DataService` to depend on `StorageRepository`.

```dart
class DataService extends ChangeNotifier {
  final StorageRepository _storage;
  
  DataService(this._storage);
  // ...
}
```

### 3. Update Providers (Completed)
Refactor `lib/providers/data_provider.dart` to separate the repository provider from the service provider.

```dart
// 1. The Repository Provider (Internal details)
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  // Switch implementation here easily (e.g., Isar vs Hive vs Mock)
  return IsarStorageRepository(); 
});

// 2. The Service Provider (Business Logic)
final dataServiceProvider = ChangeNotifierProvider<DataService>((ref) {
  final storage = ref.watch(storageRepositoryProvider);
  return DataService(storage);
});
```

### 4. Environment Configuration (Completed)
The provider setup now allows easily swapping implementations based on environment (e.g., Development vs Production vs Test) simply by overriding `storageRepositoryProvider` in the `ProviderScope`.

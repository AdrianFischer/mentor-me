# Move Database to Firebase Implementation Plan

## Overview
Migrate the application's persistence layer from the local Isar database to Cloud Firestore (Firebase). This enables data synchronization across devices and leverages cloud capabilities.

## Current State Analysis
- **Architecture:** The app uses a Repository pattern (`StorageRepository` interface).
- **Current Impl:** `IsarStorageRepository` (local NoSQL).
- **Injection:** `storageRepositoryProvider` in `lib/providers/data_provider.dart`.
- **Data Models:** Freezed models (`Project`, `Task`, etc.) in `lib/models/models.dart`.
- **Firebase:** `firebase_core` and `firebase_auth` are configured. `cloud_firestore` is missing.

## Desired End State
- App uses `FirebaseStorageRepository` backed by Cloud Firestore.
- Data persists to the cloud.
- Real-time updates sync changes.
- **Multi-Device Sync:** Data is scoped to the user. Authentication is upgraded from Anonymous to Email/Password (Hardcoded for now) so Mac and iPhone share the same `userId`.
- Old data from Isar is migrated to Firebase (one-time).

### Key Discoveries:
- `DataService` relies on a generic `onDataChanged` stream to trigger reloads. We can hook Firestore `snapshots()` to this.
- `Task` and `Subtask` structures are nested in Domain objects but normalized in Isar (mostly). In Firestore, we should use root collections for `projects` and `tasks` to allow flexible querying, linking them via IDs.
- **Auth Strategy:** To sync between devices, we cannot use Anonymous Auth. We will use `signInWithEmailAndPassword` with hardcoded credentials (personal usage).
- **Data Path:** `users/{userId}/projects`, `users/{userId}/tasks`, etc.

## Implementation Approach

### Phase 1: Infrastructure & Dependencies
- Add `cloud_firestore` to `pubspec.yaml`.
- Run `flutter pub get`.

### Phase 2: Authentication (Sync Enabler)
- Create a test user in Firebase Console (Email/Password).
- Update `main.dart` to sign in with this hardcoded user instead of `signInAnonymously`.
- Ensure `FirebaseAuth.instance.currentUser` is stable across restarts.

### Phase 3: Firebase Storage Repository
- Create `src/flutter_app/lib/data/repository/firebase_storage_repository.dart`.
- Implement `StorageRepository` interface.
- **Schema Design:**
    - `users/{uid}/projects` collection (Document ID = UUID)
    - `users/{uid}/tasks` collection (Document ID = UUID, field `projectId`)
    - `users/{uid}/conversations` collection
    - `users/{uid}/chat_messages` collection
    - `users/{uid}/knowledge` collection
- **Data Conversion:** Handle `DateTime` <-> `Timestamp` conversion.

### Phase 4: Integration & Dependency Injection
- Update `src/flutter_app/lib/providers/data_provider.dart` to return `FirebaseStorageRepository`.

### Phase 4: Data Migration (Migration Strategy)
- Create a temporary `MigrationService`.
- Logic:
    1. Check if Firestore has data (e.g., any projects?).
    2. If empty, open Isar (read-only).
    3. Iterate all entities and write to Firestore.
    4. Flag migration as done (e.g., local preference or special Firestore doc).

## Testing Strategy
- **Manual Verification:**
    1. Create a Project/Task.
    2. Restart app -> Verify persistence.
    3. Check Firebase Console -> Verify data structure.
    4. Verify relationships (Task appears under correct Project).

## Step-by-Step Plan

### 1. Add Dependencies
- Add `cloud_firestore`.

### 2. Create Firebase Repository
- Implement `init()`: Initialize Firestore.
- Implement `getAllProjects()`: Fetch `projects`, then fetch `tasks`, reconstruct hierarchy.
- Implement `saveProject`, `saveTask`, `delete...` using `set` (upsert) and `delete`.
- Implement `saveChatMessage` etc.

### 3. Switch Provider
- Swap `IsarStorageRepository` with `FirebaseStorageRepository` in `data_provider.dart`.

### 4. Migration (Optional/Subtask)
- If requested, implement migration logic. (We will verify with empty DB first).

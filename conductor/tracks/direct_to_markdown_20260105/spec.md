# Track Spec: Architecture Redesign - Direct-to-Markdown (NoSQL Removal)

## Overview
This track involves removing the local Isar database entirely to simplify the architecture. The application will transition to a pure "File-First" model where the UI interacts with an In-Memory State (Riverpod), which is persisted directly to Markdown files via a defined interface. This eliminates synchronization conflicts between a local DB and the file system.

## Functional Requirements
- **Remove Isar:** Completely remove the `isar` dependency and all related database code.
- **In-Memory Source of Truth:** The application state (Projects, Tasks) will be held entirely in memory using Riverpod providers.
- **Startup Loading:** On application launch, the system must scan, read, and parse all tracked Markdown files to populate the in-memory state.
- **Direct Persistence:** 
    - User actions (add/edit/delete) update the In-Memory State immediately (Optimistic UI).
    - The State Change triggers a direct write to the corresponding Markdown file.
- **File Watching:**
    - The app must watch the file system for external changes.
    - External edits trigger a re-parse of the specific file and an update to the In-Memory State.
- **Loop Prevention:** Implement a mechanism (e.g., file hashing or timestamp checking) to prevent the app from re-importing changes it just wrote itself.

## Non-Functional Requirements
- **Performance:** App startup time must remain under 2 seconds (parsing speed is critical).
- **Responsiveness:** UI must remain 60fps; file I/O must happen on a background isolate/thread.

## Acceptance Criteria
- [ ] The `isar` package is removed from `pubspec.yaml`.
- [ ] Application successfully loads all projects/tasks from Markdown files on restart.
- [ ] Creating a task updates the UI instantly and writes the file to disk.
- [ ] Editing a file in VS Code (or other editor) updates the running Flutter app within 1 second.
- [ ] No "flickering" or race conditions occur during rapid edits.

## Out of Scope
- Cloud synchronization (this prepares for it, but does not implement it yet).
- Complex query optimization (we assume the dataset fits comfortably in RAM).

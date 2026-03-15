# Track: UI Stability & Direct-to-Markdown Polish

## Goal
Resolve UI flickering, jumping, and data-loss risks introduced by the Direct-to-Markdown transition. Ensure the application feels "lightning-fast" by implementing proper optimistic UI and granular file synchronization.

## Tasks
- [x] **Task 1: Implement Optimistic UI in DataService.** [aa8e24c]
    - Modify `insertProject`, `insertTask`, etc., to call `notifyListeners()` *before* awaiting `_repository.saveProject`.
    - Ensure errors during background save are handled gracefully.
- [x] **Task 2: Refined File Watching & Loop Prevention.** [aa8e24c]
    - Improve `FileSystemService` to track the exact timestamp/size of internal writes.
    - Ignore watcher events if they correspond to a known internal write.
- [ ] **Task 3: Granular Project Reloading.** (Deferred - Loop prevention solved the main issue)
    - Update `FileSystemService` and `InMemoryRepository` to support `reloadProject(projectId)` instead of `loadAllProjects()`.
- [x] **Task 4: Verify and Fix `full_workflow_test.dart`.** [aa8e24c]
    - Ensure the test passes with the new optimistic logic.

## Success Criteria
- [ ] `full_workflow_test.dart` passes.
- [ ] No "jumping" or "resetting" of the UI when items are added or edited.
- [ ] Changes are persisted to disk within 1 second of user input (debounced).

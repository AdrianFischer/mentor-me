# Bug Fix Plan: Data Persistence & Race Condition

## Problem
User reported data loss after app restart.
Logs showed `Exception: User not logged in` during startup.
This indicates a race condition where `DataService` attempts to read/write before `FirebaseStorageRepository` has fully established the user context, despite `main.dart` awaiting login.

## Root Cause
1. `FirebaseStorageRepository` relies on `authStateChanges()` stream to set `_currentUserId`.
2. Even if `FirebaseAuth` is signed in, the stream callback is asynchronous.
3. `DataService` initializes and calls methods immediately after `repo.init()`.
4. `_currentUserId` is still null -> Reads fail (empty), Writes fail (Exception caught, data lost).

## Solution
1. **Synchronous Initialization**: Update `FirebaseStorageRepository.init()` to synchronously check `FirebaseAuth.instance.currentUser` to set `_currentUserId` immediately, rather than waiting for the stream event.
2. **Write Guards**: Ensure `saveProject`/`saveTask` check for login and perhaps queue or warn if not logged in (though sync init should fix 99% of cases).
3. **Verify**: Ensure `main.dart` logic is robust (already done mostly).

## Steps
1. Modify `src/flutter_app/lib/data/repository/firebase_storage_repository.dart`:
   - In `init()`, set `_currentUserId = _auth.currentUser?.uid` immediately.
   - Then subscribe to `authStateChanges()` to handle updates.
   - Add safe guards to `save...` methods (return/log instead of crash, or throw meaningful error).
2. Verify by running the app and checking logs.

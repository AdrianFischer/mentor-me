# Track Plan: Build Core Mentor Mode Infrastructure

## Phase 1: Data Model and Persistence

- [ ] Task: Define Isar collections for `MentorMessage` and `UserContext`
    - [ ] Write Tests: Create unit tests for Isar model serialization and basic CRUD.
    - [ ] Implement Feature: Define Isar collections and register them in the database service.
- [ ] Task: Create `MentorRepository` for message persistence
    - [ ] Write Tests: Mock Isar and test repository methods for saving/retrieving messages by entry ID.
    - [ ] Implement Feature: Implement the repository with Isar integration.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Data Model and Persistence' (Protocol in workflow.md)

## Phase 2: Core State and AI Logic

- [ ] Task: Implement `UserContextProvider` to manage career status and goals
    - [ ] Write Tests: Test state updates and persistence of context data.
    - [ ] Implement Feature: Create Riverpod provider to manage the global user context.
- [ ] Task: Create `MentorService` for Gemini integration
    - [ ] Write Tests: Mock `firebase_ai` and test prompt generation with the defined "Analytical/Direct" personality.
    - [ ] Implement Feature: Implement service to send messages to Gemini with system instructions.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Core State and AI Logic' (Protocol in workflow.md)

## Phase 3: UI Implementation

- [ ] Task: Create `MentorChatScreen` with multi-column integration
    - [ ] Write Tests: Widget tests for basic rendering and message display.
    - [ ] Implement Feature: Implement the UI according to the minimalist, high-contrast design.
- [ ] Task: Implement context-aware message entry linked to selections
    - [ ] Write Tests: Verify that selecting a task correctly updates the chat context.
    - [ ] Implement Feature: Connect the UI to the selection provider and mentor state.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: UI Implementation' (Protocol in workflow.md)

---
name: Implement Mentor Mode
overview: Add a new "Mentor Mode" to the AI Assistant, using "gemini-3-pro-preview" and a distinct persona focused on advice. This involves updating the AssistantService to manage separate chat sessions and the UI to allow toggling between modes.
todos:
  - id: service
    content: Update AssistantService to handle two modes and chat sessions
    status: pending
  - id: ui
    content: Update AssistantScreen to include the mode toggle
    status: pending
    dependencies:
      - service
  - id: test
    content: Test the integration
    status: pending
    dependencies:
      - ui
---

# Implement Mentor Mode

## Goal

Enable a "Mentor Mode" where the user can converse with a "wise mentor" persona using `gemini-3-pro-preview`, separate from the command-oriented Assistant.

## Architecture Changes

### [src/flutter_app/lib/services/assistant_service.dart](src/flutter_app/lib/services/assistant_service.dart)

- **State Management**:
- Add `_isMentorMode` boolean flag.
- Split `_messages` into `_assistantMessages` and `_mentorMessages`.
- Maintain two `GenerativeModel` instances: `_model` (existing) and `_mentorModel` (new, `gemini-3-pro-preview`).
- Maintain two `ChatSession` instances.
- **Methods**:
- `toggleMode()`: Switches the active mode and notifies listeners.
- `_startMentorChat()`: Initializes the mentor session with a specific system prompt including task context.
- Update `sendMessage()`: Route messages to the active session/list.

### [src/flutter_app/lib/ui/assistant_screen.dart](src/flutter_app/lib/ui/assistant_screen.dart)

- **Header**: Add a `Switch` or `SegmentedButton` to toggle between "Assistant" and "Mentor".
- **UI Feedback**: Update the header title or color to indicate the active mode (e.g., Purple for Mentor, Blue for Assistant).

### [src/flutter_app/lib/config.dart](src/flutter_app/lib/config.dart)

- Add constant for `mentorModelName` (`gemini-3-pro-preview`).

## Context Injection

- The Mentor's system prompt will include a dynamic dump of the current Project/Task structure to ensure "he feels natural" and knows what the user is working on.

## Verification

- Test toggling modes.
- Verify separate message histories.
- Verify Mentor receives context (by asking "What am I working on?").
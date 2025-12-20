# Interaction Challenges & Lessons Learned
**Date**: 2025-12-15
**Context**: Web Infrastructure Setup & AI Assistant Testing

## Challenges Interacting with the App

1.  **Keyboard Shortcut Conflicts**:
    *   **Issue**: The global `KeyboardListener` in `MyApp` (handling arrow keys and Enter for navigation) was intercepting the `Enter` key even when the user was typing in the Assistant's text field.
    *   **Impact**: Pressing "Enter" to send a message would instead trigger "Add Project", causing confusion and disrupting the workflow.
    *   **Fix**: Added a check `if (_isAssistantActive) return;` in the global handler.

2.  **State Persistence vs. Hot Restart**:
    *   **Issue**: The `web_dev_server.dart` script triggers a Hot Restart on *every* file save.
    *   **Impact**: While this ensures code changes are applied, it resets the app state (e.g., clears the chat history, resets navigation). This makes testing multi-step interactions (e.g., "Create Project" -> "Add Task") difficult if a code change is made in between.
    *   **Mitigation**: Implemented a "Mock Mode" that simulates responses quickly without needing complex state, but true persistence is still a gap.

3.  **Missing Dependencies (API Keys)**:
    *   **Issue**: The `AssistantService` required a valid Gemini API key. Without it, the app would crash or fail silently.
    *   **Impact**: Blocked testing of the UI flow.
    *   **Solution**: Implemented a robust "Mock Mode" that detects the missing key and provides simulated responses, allowing UI/UX verification without external dependencies.

4.  **Browser Tool Latency**:
    *   **Issue**: The `browser_click` and `browser_type` tools have overhead.
    *   **Impact**: Testing a simple flow ("Type message" -> "Send") takes multiple tool round-trips (Navigate -> Snapshot -> Type -> Wait -> Snapshot -> Verify).
    *   **Lesson**: Batching actions where possible and using `browser_wait_for` is crucial to avoid "missed" states.

## Lessons on Tool Usage Optimization

1.  **Mocking for Velocity**:
    *   **Lesson**: When a feature depends on an external service (AI, Database), don't wait for the "real" thing to be set up. Implement a "Mock Mode" immediately.
    *   **Benefit**: Allowed me to verify the *integration* (Button -> Event -> Response -> UI Update) without blocking on the *implementation* of the API client. This saved multiple turns of "asking for keys" or "debugging auth".

2.  **Precise Browser Waits**:
    *   **Lesson**: Using `browser_wait_for(text: "...")` is significantly more reliable than `browser_snapshot` in a loop.
    *   **Benefit**: Reduced the number of "Snapshot -> Page loading... -> Snapshot -> Still loading..." cycles. I used `browser_wait_for` to ensure the "Conversation" UI was visible before trying to interact with it.

3.  **Background Process Management**:
    *   **Lesson**: Managing the `flutter run` process in the background requires care.
    *   **Benefit**: Checking for existing processes (`ps aux`) and killing orphans prevented "Port 3000 already in use" errors, which would have wasted tool calls on debugging connection failures.

4.  **Targeted File Reading**:
    *   **Lesson**: Instead of reading the entire `lib/` folder, I focused on the specific files involved in the feature (`assistant_service.dart`, `assistant_screen.dart`, `app.dart`).
    *   **Benefit**: Reduced context usage and noise.







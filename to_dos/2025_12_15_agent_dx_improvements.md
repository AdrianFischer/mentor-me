Improve Developer Experience (DX) and Testing Infrastructure for Autonomous Agents
agent_dx_improvements
Create tools and patterns to make future agent interactions with the app more robust and efficient.

  Summary
State: Completed
Focus: Debug Overlay

Log Book
2025-12-15 01:35:00 - Implemented `DebugDataService` and State Seeding.
  - Created `services/debug_data_service.dart`.
  - Added `?seed=complex_tree` support in `MyApp.initState`.
  - Added `clear()` method to `DataService`.
2025-12-15 01:30:00 - Implemented Deterministic Widget Keys in `EditableColumn`. Keys are now based on column title and index (e.g., `projects_item_0`).
2025-12-15 01:05:00 - Started work on Agent DX improvements. Prioritizing Deterministic Widget Keys and State Seeding.
2025-12-15 02:00:00 - Implemented Debug Overlay.
  - Created `lib/ui/widgets/debug_overlay.dart`.
  - Integrated into `MyApp`.
  - Verified toggle button and content display (Focus, Last Key).
2025-12-15 01:00:00 - Task created based on lessons learned from initial Web Infra setup.

## Proposed Tasks

1. **State Seeding & Deep Linking**
   - **Problem**: Hot Restart wipes state. Agents waste steps navigating to specific screens (e.g., "Add Subtask" requires creating Project -> Task first).
   - **Solution**: Implement a `DebugDataService` or URL parameter parsing (e.g., `?seed=complex_tree`) that initializes the `DataProvider` with a pre-populated tree of Projects, Tasks, and Subtasks.
   - **Benefit**: Agent can test "Delete Subtask" immediately upon load.

2. **Deterministic Widget Keys**
   - **Problem**: Finding elements via text ("New Item") is flaky if multiple exist.
   - **Solution**: Enforce a strict `ValueKey` naming convention for all interactive lists (e.g., `Key('project_list_item_0')`, `Key('task_input_field')`). Add `Semantics` widgets for better accessibility tool discovery.
   - **Benefit**: `browser_click(ref: ...)` becomes 100% reliable.

3. **Visual Debug Overlay**
   - **Problem**: Invisible state (Focus, Shortcuts) is hard to debug via screenshots.
   - **Solution**: Add a toggleable "Debug Overlay" that displays:
     - Current `FocusNode` debug label.
     - Active `Shortcuts` or `Intent` mappings.
     - Last `KeyEvent` received.
   - **Benefit**: Agent can "see" why `Enter` didn't work (e.g., "Focus: None").

4. **Runtime Mock Toggling**
   - **Problem**: Switching between Mock AI and Real AI currently requires code edits.
   - **Solution**: Add a visible "DevTools" drawer or button in the app to toggle `AssistantService.mockMode` at runtime.
   - **Benefit**: seamless transition between logic testing and integration testing.

5. **Action Log / Status Bar**
   - **Problem**: Errors are often buried in console logs.
   - **Solution**: Add a persistent footer that shows the last system status message (e.g., "Error: API Key missing", "Action: Project Added").
   - **Benefit**: Agent sees success/failure status directly in the `browser_snapshot`.


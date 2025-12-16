# Feature List & Functionality Reference
**Version**: 2025-12-15
**Status**: Active Implementation
**Context**: Reference for future agents to preserve existing functionality.

## 1. Core Infrastructure & Pipeline
*   **Autonomous Development Pipeline**:
    *   Script: `src/scripts/autonomous_flutter.dart`
    *   **Functionality**:
        *   Starts Flutter app on macOS (`flutter run -d macos`).
        *   Watches `lib/` for changes (recursively).
        *   **Debounced Hot Reload**: Triggers on file save (500ms debounce).
        *   **Automated Verification**: Captures `current_state.png` after reload (800ms delay).
        *   **VM Service Integration**: Automatically connects to VM Service for reliable screenshotting.

## 2. User Interface & Layout
### Core Layout (3-Column Split)
*   **Column 1: Projects / Navigation**
    *   Background: Light Grey (`#F5F5F7`).
    *   Content:
        *   **"✨ AI Assistant"**: Fixed top item, activates Assistant View.
        *   **Project List**: Editable list of projects.
    *   **Behavior**:
        *   Selecting a project filters Column 2.
        *   Selecting "AI Assistant" hides Column 2/3 and shows Assistant Split View.

*   **Column 2: Tasks**
    *   Background: White (`#FFFFFF`).
    *   Content: Task list for the selected project.
    *   **Behavior**:
        *   Visible only when a valid Project is selected.
        *   Placeholder: "Select a Project" if state is invalid.

*   **Column 3: Subtasks / Detail**
    *   Background: Off-White (`#FAFAFA`).
    *   Content: Subtask list for the selected task.
    *   **Behavior**:
        *   Visible only when a valid Task is selected.
        *   Placeholder: "Select a Task" if state is invalid.

### Assistant View (Overlay/Split)
*   **Activation**: Triggered by selecting "✨ AI Assistant" in Column 1.
*   **Layout**: 2-Column Split (replacing Columns 2 & 3).
    *   **Left (Conversation)**: Chat interface with User/AI message bubbles.
    *   **Right (Action Log)**: Read-only list of executed actions (history).

### Component: Editable Column (`EditableColumn`)
*   **Visual Style**:
    *   Title: Large, Bold (Things 3 style).
    *   Add Button: Blue circle icon + tooltip.
    *   Selection: White card background with subtle shadow.
    *   Focus: Subtle blue border on active item.
*   **Interaction**:
    *   **Inline Editing**: `TextField` for direct content manipulation.
    *   **Checkboxes**: Visual toggle (Circle shape), supports `Meta + Enter` shortcut.
    *   **Drag & Drop**: *Not yet implemented*.

## 3. Interaction & Input
### Keyboard Shortcuts (CRITICAL - DO NOT BREAK)
*   **Navigation**:
    *   `Arrow Up/Down`: Move selection within the current column.
    *   `Arrow Left/Right`: Move focus between columns (Project <-> Task <-> Subtask).
*   **Editing**:
    *   `Enter`: Creates a new empty item *below* the current one.
    *   `Meta + Enter` (Cmd+Enter): Toggles the checkbox/status of the current item.
    *   `Backspace` (on empty item): Deletes the item and moves focus to the previous item.

### Focus Management
*   **Auto-Focus**: Newly created items are automatically focused.
*   **Column Focus**: Active column allows keyboard navigation.
*   **Selection State**:
    *   `_selectedProjectId`, `_selectedTaskId`, `_selectedSubtaskId` drive the view state.
    *   App handles cleanup of empty items when navigating away (conditional).

## 4. AI Integration
### Architecture
*   **Provider**: `AssistantService` (Riverpod).
*   **Tool Registry**: `ai_tools/tool_registry.dart` maps LLM calls to app functions.
*   **Tools Available to Agent**:
    *   `add_project`, `update_project`, `delete_item`
    *   `add_task`, `update_task`
    *   `add_subtask`

### Workflow
1.  **User Input**: Voice (Mic button) or Text.
2.  **Processing**: AI generates a plan and executes tools automatically (Model: `gemini-2.5-flash`).
3.  **Execution**: `ToolRegistry` executes actions immediately.
4.  **Feedback**:
    *   **Chat**: AI confirms action ("I created project X").
    *   **Action Log**: Right column displays a read-only history of executed actions (Green checkmarks).
5.  **Review**: User sees the result instantly in the app state.

## 5. Data Management
*   **Service**: `DataService` / `DataProvider`.
*   **Structure**: In-memory hierarchy (`Project` > `Task` > `Subtask`).
*   **Persistence**: *Basic LocalStorage implemented but primarily in-memory for prototype*.

## 6. Known Deviations from Original Spec
*   **Task Card**: The spec described an "Expanded Task Card" in Column 2. The implementation currently uses Column 3 for Subtasks, effectively treating it as the "Detail View".
*   **Visuals**: Material Design widgets are used as proxies for the custom "Paper" aesthetic.


# Project Context

**Date**: 2025-12-12 (Updated: 2025-12-15)
**Context**: Initial project setup and understanding, design specifications, and feature documentation

## Project Overview
- **Repository Purpose**: This repository (`AssistedIntelligence`) is for to-do lists and mentor capabilities
- **Not a Codebase**: The actual codebases for projects/customers are stored elsewhere

## GLT Customer
- **Customer**: GLT
- **System Type**: Grid-based storage and retrieval system
- **Release Requirement**: New releases must not be slower than previous releases in throughput
- **Codebase Location**: External to this repository

## Key Principles
- Performance is critical: throughput must be maintained or improved
- Grid-based architecture for storage and retrieval

## Todo File Structure Requirements
- Each todo file must include a "Summary" section with:
  - **State**: Not more than 5 words describing current state
  - **Focus**: Not more than 5 words describing what to focus on
- The Summary section must be copied to `overview.md` for quick reference
- This applies to all new and existing todos

## App Design Specifications (2025-12-13)

### Design Goal
- **Aesthetic**: "Professional Productivity" (Inspired by *Things 3*)
- **Status**: Approved
- **Platform**: Flutter Desktop
- **Input**: 100% Keyboard-driven. NO MOUSE interaction.
- **Style**: High-efficiency, keyboard-centric (Vim/Raycast/Superhuman inspired)

### Core Layout Structure (3-Column Split View)
**Column 1: Navigation (Sidebar)**
- **Role**: Context Switching
- **Visuals**: Translucent, subtle light gray background (`#F5F5F7` or similar)
- **Content**:
  - **Inbox / Today / Upcoming** (Top section, colorful icons)
  - **Projects List** (Bottom section, clean typography)
- **Typography**: San Francisco, Regular weight

**Column 2: The Task List (Canvas)**
- **Role**: The main workspace
- **Visuals**: Pure white background (`#FFFFFF`). Paper-like feel. No heavy borders
- **Interaction**:
  - **List Items**: Clean text rows with generous whitespace (12-16px padding)
  - **Selection**: "Pill" shape highlight (Blue `#007AFF` or Light Gray in expanded state)

**Column 3: The Agent (Assistant)**
- **Role**: AI-powered execution and context
- **Visuals**: Continues the clean, borderless aesthetic of Column 2
- **Behavior**:
  - **Context Aware**: The agent knows the context of the selected task in Column 2
  - **Chat Interface**: Minimalist message bubbles (User = Blue, AI = Gray)
  - **Session Management**: Ability to "Reset" or "Archive" a chat session to start fresh on a new task

### Expanded Task Card Component
When a user selects a task to work on, it expands into a detailed card, replacing the simple row.

**Visual Design**
- **Container**: White card with rounded corners (8-12px radius) and a soft, diffuse shadow
- **Background**: When expanded, the list background acts as a surface for the card to float on

**Content Hierarchy**
1. **Header**:
   - **Checkbox**: Square, standard
   - **Title**: Large, Bold text
   - **Notes**: Subtle gray text below title (for deadlines or brief context)
2. **Body (The "Agent Summary")**:
   - A text block summarizing the current status or the result of the Agent's work
3. **Subtasks (Checklist)**:
   - Linear list of subtasks
   - **Active State**: The subtask currently being worked on is highlighted with a **Light Gray Pill** background
   - **Actions**: "Hamburger" menu or action icons appear on the active row
4. **Footer**:
   - Minimal icon toolbar aligned right (Calendar, Tags, Flag)

### Design Principles
- **Invisible Design**: Eliminate unnecessary borders, lines, and "container" boxes. Use whitespace to separate elements
- **Typography First**: Use font weight (Bold vs. Regular) and color (Black vs. Gray) to establish hierarchy, not background colors
- **Paper Metaphor**: The interface should feel like interacting with a clean sheet of paper or a set of cards, not a database grid

### Navigation Model
- **Layout**: Split View (Left: Task List, Right: Task Details)
- **Key Bindings**:
  - `Arrow Up/Down`: Traverse Left Pane list. Instant preview in Right Pane
  - `Arrow Right`: Shift focus to Right Pane (Dive in)
  - `Arrow Left`: Return focus to Left Pane (Pop out)
  - `Enter`: Edit selected element (Inline editing)
  - `Space`: Summon "AI Agent" overlay (Conversational interface)
  - `Esc`: Cancel/Exit edit mode

### Data Source
- **Local Markdown files**:
  - `overview.md`: Summary table of all tasks (List View source)
  - `to_dos/*.md`: Detailed task files (Detail View source)
- **File Structure**:
  - **Header**: Description, Identifier
  - **Summary**: State (e.g., Preparing), Focus (e.g., Podcast Rehearsal)
  - **Log Book**: Chronological updates

### Selected Top 3 Design Concepts (Refined)

**1. The Neuro-Link (Score: 10/10)**
- **Visual Metaphor**: Bi-Directional Command Line. A modernized terminal that predicts intent. Dark mode, monospaced fonts, but with fluid, organic transitions
- **The Innovation**: "Fluid State Transitions" - The boundary between "Navigation" and "Action" is blurred. As you type, the interface morphs
- **Refinement - "Contextual Action Hints"**: When typing or hovering, the UI displays ghost-text suggestions for available keyboard commands based on the exact context. The Split View is dynamic; the active pane expands to 70% width, while the inactive one shrinks to 30%

**2. The Glass Cockpit (Score: 9.8/10)**
- **Visual Metaphor**: Fighter Jet HUD. High-contrast green/amber text on semi-transparent dark layers
- **The Innovation**: "Heads-Up Overlays" - Instead of a hard split view, the Details Pane is a glass layer that slides in *over* the list when you press `Arrow Right`
- **Refinement - "Critical Path Highlighting"**: When the overlay is active, critical information (like Next Actions or Deadlines) glows with slightly higher intensity

**3. The Tiling Master (Score: 9.5/10)**
- **Visual Metaphor**: Tiling Window Manager (i3 / Sway). Sharp borders, absolute maximizing of screen real estate
- **The Innovation**: "Infinite Context Stack" - If a task has sub-tasks or linked notes, `Arrow Right` opens a *third* column, pushing the parent list to the left
- **Refinement - "Minimap Navigation"**: A small "Minimap" or breadcrumb bar in the top-right corner visualizes the entire column depth, highlighting your current active column

## Feature List & Functionality (2025-12-15)

### Core Infrastructure & Pipeline
**Autonomous Development Pipeline**
- Script: `src/scripts/autonomous_flutter.dart`
- **Functionality**:
  - Starts Flutter app on macOS (`flutter run -d macos`)
  - Watches `lib/` for changes (recursively)
  - **Debounced Hot Reload**: Triggers on file save (500ms debounce)
  - **Automated Verification**: Captures `current_state.png` after reload (800ms delay)
  - **VM Service Integration**: Automatically connects to VM Service for reliable screenshotting

### User Interface & Layout

**Core Layout (3-Column Split)**
- **Column 1: Projects / Navigation**
  - Background: Light Grey (`#F5F5F7`)
  - Content:
    - **"✨ AI Assistant"**: Fixed top item, activates Assistant View
    - **Project List**: Editable list of projects
  - **Behavior**:
    - Selecting a project filters Column 2
    - Selecting "AI Assistant" hides Column 2/3 and shows Assistant Split View

- **Column 2: Tasks**
  - Background: White (`#FFFFFF`)
  - Content: Task list for the selected project
  - **Behavior**:
    - Visible only when a valid Project is selected
    - Placeholder: "Select a Project" if state is invalid

- **Column 3: Subtasks / Detail**
  - Background: Off-White (`#FAFAFA`)
  - Content: Subtask list for the selected task
  - **Behavior**:
    - Visible only when a valid Task is selected
    - Placeholder: "Select a Task" if state is invalid

**Assistant View (Overlay/Split)**
- **Activation**: Triggered by selecting "✨ AI Assistant" in Column 1
- **Layout**: 2-Column Split (replacing Columns 2 & 3)
  - **Left (Conversation)**: Chat interface with User/AI message bubbles
  - **Right (Action Log)**: Read-only list of executed actions (history)

**Component: Editable Column (`EditableColumn`)**
- **Visual Style**:
  - Title: Large, Bold (Things 3 style)
  - Add Button: Blue circle icon + tooltip
  - Selection: White card background with subtle shadow
  - Focus: Subtle blue border on active item
- **Interaction**:
  - **Inline Editing**: `TextField` for direct content manipulation
  - **Checkboxes**: Visual toggle (Circle shape), supports `Meta + Enter` shortcut
  - **Drag & Drop**: *Not yet implemented*

### Interaction & Input

**Keyboard Shortcuts (CRITICAL - DO NOT BREAK)**
- **Navigation**:
  - `Arrow Up/Down`: Move selection within the current column
  - `Arrow Left/Right`: Move focus between columns (Project <-> Task <-> Subtask)
- **Editing**:
  - `Enter`: Creates a new empty item *below* the current one
  - `Meta + Enter` (Cmd+Enter): Toggles the checkbox/status of the current item
  - `Backspace` (on empty item): Deletes the item and moves focus to the previous item

**Focus Management**
- **Auto-Focus**: Newly created items are automatically focused
- **Column Focus**: Active column allows keyboard navigation
- **Selection State**:
  - `_selectedProjectId`, `_selectedTaskId`, `_selectedSubtaskId` drive the view state
  - App handles cleanup of empty items when navigating away (conditional)

### AI Integration

**Architecture**
- **Provider**: `AssistantService` (Riverpod)
- **Tool Registry**: `ai_tools/tool_registry.dart` maps LLM calls to app functions
- **Tools Available to Agent**:
  - `add_project`, `update_project`, `delete_item`
  - `add_task`, `update_task`
  - `add_subtask`

**Workflow**
1. **User Input**: Voice (Mic button) or Text
2. **Processing**: AI generates a plan and executes tools automatically (Model: `gemini-2.5-flash`)
3. **Execution**: `ToolRegistry` executes actions immediately
4. **Feedback**:
   - **Chat**: AI confirms action ("I created project X")
   - **Action Log**: Right column displays a read-only history of executed actions (Green checkmarks)
5. **Review**: User sees the result instantly in the app state

### Data Management
- **Service**: `DataService` / `DataProvider`
- **Structure**: In-memory hierarchy (`Project` > `Task` > `Subtask`)
- **Persistence**: *Basic LocalStorage implemented but primarily in-memory for prototype*

### Known Deviations from Original Spec
- **Task Card**: The spec described an "Expanded Task Card" in Column 2. The implementation currently uses Column 3 for Subtasks, effectively treating it as the "Detail View"
- **Visuals**: Material Design widgets are used as proxies for the custom "Paper" aesthetic

## Interaction Challenges & Lessons Learned (2025-12-15)

### Challenges Interacting with the App

**1. Keyboard Shortcut Conflicts**
- **Issue**: The global `KeyboardListener` in `MyApp` (handling arrow keys and Enter for navigation) was intercepting the `Enter` key even when the user was typing in the Assistant's text field
- **Impact**: Pressing "Enter" to send a message would instead trigger "Add Project", causing confusion and disrupting the workflow
- **Fix**: Added a check `if (_isAssistantActive) return;` in the global handler

**2. State Persistence vs. Hot Restart**
- **Issue**: The `web_dev_server.dart` script triggers a Hot Restart on *every* file save
- **Impact**: While this ensures code changes are applied, it resets the app state (e.g., clears the chat history, resets navigation). This makes testing multi-step interactions (e.g., "Create Project" -> "Add Task") difficult if a code change is made in between
- **Mitigation**: Implemented a "Mock Mode" that simulates responses quickly without needing complex state, but true persistence is still a gap

**3. Missing Dependencies (API Keys)**
- **Issue**: The `AssistantService` required a valid Gemini API key. Without it, the app would crash or fail silently
- **Impact**: Blocked testing of the UI flow
- **Solution**: Implemented a robust "Mock Mode" that detects the missing key and provides simulated responses, allowing UI/UX verification without external dependencies

**4. Browser Tool Latency**
- **Issue**: The `browser_click` and `browser_type` tools have overhead
- **Impact**: Testing a simple flow ("Type message" -> "Send") takes multiple tool round-trips (Navigate -> Snapshot -> Type -> Wait -> Snapshot -> Verify)
- **Lesson**: Batching actions where possible and using `browser_wait_for` is crucial to avoid "missed" states

### Lessons on Tool Usage Optimization

**1. Mocking for Velocity**
- **Lesson**: When a feature depends on an external service (AI, Database), don't wait for the "real" thing to be set up. Implement a "Mock Mode" immediately
- **Benefit**: Allowed verification of the *integration* (Button -> Event -> Response -> UI Update) without blocking on the *implementation* of the API client. This saved multiple turns of "asking for keys" or "debugging auth"

**2. Precise Browser Waits**
- **Lesson**: Using `browser_wait_for(text: "...")` is significantly more reliable than `browser_snapshot` in a loop
- **Benefit**: Reduced the number of "Snapshot -> Page loading... -> Snapshot -> Still loading..." cycles. Used `browser_wait_for` to ensure the "Conversation" UI was visible before trying to interact with it

**3. Background Process Management**
- **Lesson**: Managing the `flutter run` process in the background requires care
- **Benefit**: Checking for existing processes (`ps aux`) and killing orphans prevented "Port 3000 already in use" errors, which would have wasted tool calls on debugging connection failures

**4. Targeted File Reading**
- **Lesson**: Instead of reading the entire `lib/` folder, focus on the specific files involved in the feature (`assistant_service.dart`, `assistant_screen.dart`, `app.dart`)
- **Benefit**: Reduced context usage and noise

## Responsive Layout Implementation (2025-12-18)

### Overview
Instead of a device-based approach, a layout-based approach was implemented using `LayoutBuilder`.

### Implementation Details
- **Breakpoint**: 1260px width for main app
- **Strict Layouts**: The app now strictly differentiates between two layout modes:
  - **One Column (Mobile)**: Used when width < 1260px. Shows a single column. In AI Assistant mode, this is the conversation column with actions as popups
  - **Three Columns (Desktop)**: Used when width >= 1260px. Shows three columns with a 1:2:2 ratio (Projects: 1/5, Tasks/Conversation: 2/5, Subtasks/Action Log: 2/5). This provides more space for the primary content columns. In AI Assistant mode, this is [Projects] | [Chat & Action Log (combined flex 4)]
- **Navigation**:
  - Selecting an item in a column navigates to the next level (one column to the right)
  - A back button was added to the header of child columns (`Tasks`, `Subtasks`) to allow navigating back to the parent column
- **AI Assistant Simplification**: Removed internal responsive logic within `AssistantScreen`. It now directly inherits the layout mode from the main app, ensuring a consistent transition between 1 and 3 columns without intermediate states
- **UI Components**:
  - `EditableColumn` was updated to support an `onBack` callback and display a back icon
  - `FloatingActionButton` was added to the mobile layout for quick task creation
- **Suggested Actions**: Pending actions appear as popups (overlay cards) in 1-column mode to save space

### Technical Challenges
- **Web Testing**: To verify the layout in the browser tool, a `MemoryStorageRepository` was created to avoid Isar's web compatibility issues with large integers. However, for the final commit, the native Isar persistence was restored to maintain user data on macOS

## Archive Completed Elements Feature (2025-12-30)

### Overview
Implementation plan for an "Archive" feature that allows users to hide completed tasks and subtasks. This will be controlled by a toggle at the top of each relevant column.

### Current State Analysis
- **Rendering**: `src/flutter_app/lib/app.dart` renders tasks and subtasks using `EditableColumn`
- **Logic**: No filtering is currently applied to the task/subtask lists before they are passed to the UI
- **State**: `SelectionState` (Riverpod) manages current selection but doesn't track filter states

### Desired End State
- Users can toggle between "Show Completed" and "Hide Completed" (Archive) for Tasks and Subtasks
- Completed items are hidden when Archive mode is active
- Keyboard navigation correctly skips hidden items

### Key Implementation Locations
- `src/flutter_app/lib/app.dart:294` (`_buildTaskColumn`) and `src/flutter_app/lib/app.dart:374` (`_buildSubtaskColumn`) are the primary locations for list generation
- `src/flutter_app/lib/providers/selection_provider.dart` is the central place for selection state

### Scope Limitations
- Archiving projects (out of scope for now, as projects are fewer)
- Automatic archiving (only manual toggle)
- Complex multi-level filtering

### Implementation Approach
1. **State**: Update `SelectionState` to include `showCompletedTasks` and `showCompletedSubtasks`
2. **UI - Toggle**: Add a "Show/Hide Completed" toggle in the `EditableColumn` header
3. **UI - Filtering**: Apply filters in `app.dart` based on the new state
4. **Selection Logic**: Update `SelectionNotifier.moveSelection` to skip items that are not visible

### Testing Strategy
1. Mark a task as completed
2. Toggle "Hide Completed". Verify the task disappears
3. Toggle "Show Completed". Verify the task reappears
4. With "Hide Completed" active, navigate with arrows. Verify you cannot select hidden items

## macOS App Sandbox & Permissions (2025-12-16)

### The Finding
Disabling the **App Sandbox** (`com.apple.security.app-sandbox = false`) in macOS entitlements resolves two distinct classes of issues for internal/developer builds:

1. **File System Access**: It allows the app to write to arbitrary paths (like the workspace `to_dos/` directory) without requiring `NSOpenPanel` user interaction or "User Selected File" entitlements
2. **Permission Plugins**: It resolves `MissingPluginException` errors when requesting sensitive permissions (Microphone, Camera). In a sandboxed environment, if entitlements or signing are slightly misconfigured, the OS blocks the permission request *before* it reaches the plugin, causing the plugin to crash or return a "missing implementation" error

### Implication for Development
For internal tools or "autonomous" apps that need to interact with the developer's environment (like this project):
- **Debug/Profile Builds**: Explicitly **DISABLE** the sandbox in `DebugProfile.entitlements`. This grants "God Mode" access to the filesystem and hardware, simplifying development
- **Release/Store Builds**: MUST have the sandbox enabled. This requires careful configuration of `Network Client`, `Audio Input`, and `User Selected File` entitlements

### Configuration
**File**: `macos/Runner/DebugProfile.entitlements`
```xml
<key>com.apple.security.app-sandbox</key>
<false/>
```

### Related Errors
- `OS Error: Operation not permitted, errno = 1` (File System)
- `MissingPluginException(No implementation found for method requestPermissions)` (Microphone/Camera)

## Related Topics
- Release preparation process
- Performance benchmarking requirements
- Todo management and tracking
- Flutter desktop app development
- Keyboard-driven UI design
- AI agent integration
- Web infrastructure setup
- Responsive design patterns
- macOS development and permissions


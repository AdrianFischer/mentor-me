# Flutter App & Autonomous Pipeline Implementation Plan

## Overview
This plan details the creation of a new Flutter application within `knowledge_base/design_specs_2025_12_13/` and the setup of an autonomous "Change -> Hot Reload -> Verify" pipeline. This pipeline will allow for rapid iteration by automatically applying changes and generating visual verification artifacts (screenshots) without manual interaction.

## Current State Analysis
- **Location**: `knowledge_base/design_specs_2025_12_13/` exists and contains design assets.
- **Status**: ✅ Phase 1 Complete - Flutter app initialized at `knowledge_base/design_specs_2025_12_13/flutter_app/`
- **Status**: ✅ Phase 2 Complete - Autonomous pipeline script created at `src/scripts/autonomous_flutter.dart`
- **Next**: Phase 3 - Validation & Testing

## Desired End State
1.  A functional Flutter app running on macOS (initially).
2.  A script (`scripts/autonomous_flutter.dart`) that:
    -   Starts the app.
    -   Watches `lib/` for changes.
    -   Triggers Hot Reload automatically.
    -   Captures a screenshot (`current_state.png`) immediately after reload for verification.
3.  Verification of the pipeline by changing a UI element and seeing the screenshot update automatically.

## Implementation Approach
We will build a wrapper script in Dart that spawns the `flutter run` process. This gives us full control over `stdin` (to send 'r' for reload) and `stdout` (to know when reload finishes).

### Key Discoveries & Patterns
-   **Flutter Tooling**: `flutter run --machine` or standard `flutter run` allows controlling the process via stdin.
-   **File Watching**: Dart's `Directory.watch()` is efficient for monitoring the `lib/` folder.
-   **Verification**: `flutter screenshot` works with connected devices/simulators to capture the current screen state.

## Phase 1: App Initialization ✅ COMPLETE
### Overview
Initialize the standard Flutter project structure in the target directory.

### Steps Completed
1.  **Create Project**: ✅ Flutter project created at `knowledge_base/design_specs_2025_12_13/flutter_app/`
2.  **Verify Setup**: ✅ App builds and runs on macOS
3.  **Cleanup**: ✅ Default counter app boilerplate removed; minimal scaffold with "Pipeline Fully Operational" message

### Current App State
- **Main Entry**: `lib/main.dart` contains a simple MaterialApp with a centered text widget
- **Platform**: Configured for macOS
- **Ready for**: Design implementation (Phase 4)

## Phase 2: The Autonomous Pipeline Script ✅ COMPLETE
### Overview
Create the `scripts/autonomous_flutter.dart` tool to manage the development lifecycle.

### Implementation Location
- **Script Path**: `src/scripts/autonomous_flutter.dart`
- **Status**: Fully implemented with enhanced features

### Components Implemented
1.  **Process Manager**: ✅ Spawns `flutter run -d macos` with proper working directory
2.  **Output Parser**: ✅ Listens to `stdout` for "Reloaded", "Restarted", or "Syncing files..." confirmation
3.  **VM Service URL Capture**: ✅ Automatically captures VM Service URL for enhanced screenshot functionality
4.  **File Watcher**: ✅ Monitors `lib/**/*.dart` recursively with debouncing (500ms)
5.  **Action Trigger**:
    -   ✅ On File Save -> Debounced -> Send 'r' to `stdin`
    -   ✅ On Reload Complete -> 800ms delay -> Trigger `flutter screenshot`
6.  **Error Handling**: ✅ Proper stderr streaming and exit code checking

### Enhancements Over Draft
- **Debouncing**: Prevents multiple reload triggers from rapid file saves
- **VM Service Integration**: Captures and uses VM Service URL for more reliable screenshots on macOS
- **Path Management**: Handles relative paths correctly from project root
- **Better Logging**: Clear emoji-based status indicators for pipeline events
- **Delay Before Screenshot**: 800ms delay ensures render completion before capture

### Usage
```bash
# From project root
dart run src/scripts/autonomous_flutter.dart
```

The script will:
1. Start Flutter app on macOS
2. Watch for changes in `lib/` directory
3. Automatically trigger hot reload on file save
4. Capture screenshot to `knowledge_base/design_specs_2025_12_13/current_state.png` after each reload

## Phase 3: Validation & Iteration 🔄 IN PROGRESS
### Overview
Test the pipeline with a real change to verify end-to-end functionality.

### Steps
1.  ✅ Run the autonomous script: `dart run src/scripts/autonomous_flutter.dart`
2.  ⏳ Modify `main.dart` (e.g., change `Scaffold` background color or text content)
3.  ⏳ Save the file
4.  ⏳ **Verify**: Check if `current_state.png` is updated and shows the new changes without manual intervention

### Expected Behavior
- Script should detect file change within 500ms
- Hot reload should trigger automatically
- Screenshot should be captured ~800ms after reload completes
- Screenshot saved to: `knowledge_base/design_specs_2025_12_13/current_state.png`

### Troubleshooting
- **Screenshot fails**: Ensure VM Service URL is captured (check console output for 🔌 indicator)
- **Hot reload not triggering**: Verify file is saved and ends with `.dart` extension
- **Process hangs**: Check if Flutter app is already running; kill existing processes first

## Phase 4: Implementation of Design Specs ⏳ PENDING
### Overview
Use the established pipeline to implement the 3-column "Things 3" layout defined in `README.md`.

### Design Reference
- **Spec Document**: `knowledge_base/design_specs_2025_12_13/README.md`
- **Layout Overview**: `knowledge_base/design_specs_2025_12_13/layout_overview.png`
- **Task Card Component**: `knowledge_base/design_specs_2025_12_13/component_task_card.png`

### Implementation Steps (Post-Validation)
1.  **MainLayout Widget** (3-column structure):
    - Column 1: Navigation Sidebar (`#F5F5F7` background)
    - Column 2: Task List Canvas (white background, `#FFFFFF`)
    - Column 3: Agent Chat Interface (white background, borderless)

2.  **TaskCard Component**:
    - Expandable card with rounded corners (8-12px radius)
    - Header: Checkbox, Title, Notes
    - Body: Agent Summary text block
    - Subtasks: Checklist with active state highlighting
    - Footer: Icon toolbar (Calendar, Tags, Flag)

3.  **AgentChat Widget**:
    - Minimalist chat interface
    - Context-aware (knows selected task)
    - Message bubbles (User = Blue `#007AFF`, AI = Gray)
    - Session management (Reset/Archive)

### Design Principles to Follow
- **Invisible Design**: Eliminate unnecessary borders, use whitespace
- **Typography First**: Use font weight and color for hierarchy
- **Paper Metaphor**: Clean, card-based interface

### Development Workflow
1. Make changes to Flutter code in `lib/`
2. Save file → Pipeline auto-reloads
3. Screenshot captured automatically
4. Review `current_state.png` to verify visual changes
5. Iterate rapidly without manual intervention

## Implementation Notes & Learnings

### Key Technical Decisions
1. **Dart Script vs. Shell Script**: Chose Dart for better process control and cross-platform compatibility
2. **Debouncing**: 500ms debounce prevents excessive reloads from IDE auto-save events
3. **Screenshot Delay**: 800ms delay ensures UI is fully rendered before capture
4. **VM Service URL**: Capturing this enables more reliable screenshots on macOS via Skia backend

### Known Limitations
- Screenshot functionality may require VM Service URL on macOS (captured automatically)
- File watching only monitors `.dart` files in `lib/` directory
- Process must be manually terminated (Ctrl+C) when done

### Future Enhancements
- Add support for multiple device targets
- Implement screenshot comparison/diffing for automated visual regression testing
- Add configuration file for custom paths and delays
- Support for hot restart (full app restart) vs. hot reload

## References
-   Inspired by `flutter-auto-reload` tools
-   Flutter `flutter run` documentation
-   Flutter Screenshot API: `flutter screenshot --help`


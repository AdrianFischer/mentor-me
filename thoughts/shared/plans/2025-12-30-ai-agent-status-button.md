# AI Agent Status Button Implementation Plan

## Overview
Implement a new "AI Agent Status" button for tasks and subtasks in the Flutter app. This button allows users to signal when a task is ready for an AI agent, and allows agents to update their progress. The status will be exposed via MCP to enable autonomous agents to find and work on tasks.

## Current State Analysis
- Tasks and subtasks have a `isCompleted` boolean state.
- UI uses `EditableItemWidget` to display a checkbox and title.
- Data is persisted via Isar.
- MCP server provides tools to interact with the app.

## Desired End State
- Tasks and subtasks have an `aiStatus` field with four states: `notReady` (Paused), `ready`, `inProgress`, and `done`.
- A new button appears next to the checkbox in the UI, indicating the AI status.
- Clicking the button cycles through the statuses (or opens a menu).
- AI Status is persisted.
- MCP server provides tools to read and update `aiStatus`.
- If `aiStatus` is set to `done`, the task checkbox is automatically checked.

### Key Discoveries:
- `src/flutter_app/lib/models/models.dart`: Domain models for Task and Subtask.
- `src/flutter_app/lib/data/schema/isar_models.dart`: Isar schema for persistence.
- `src/flutter_app/lib/ui/widgets/editable_item_widget.dart`: UI for task items.
- `src/flutter_app/lib/services/mcp_server.dart`: MCP server implementation.

## What We're NOT Doing
- Implementing the actual autonomous agents in this task.
- Changing the existing checkbox behavior for anything other than the `done` status synchronization.

## Implementation Approach
1. **Data Model & Persistence**: Update models and Isar schema to include `aiStatus`.
2. **UI Integration**: Add the status button to `EditableItemWidget`.
3. **Business Logic**: Update `DataService` to handle status changes and synchronization with `isCompleted`.
4. **MCP Tools**: Add tools for agents to get/set the AI status.

## Phase 1: Data Model and Persistence
### Overview
Update the data structures to support the new status.

### Changes Required:
#### 1. Define AiStatus Enum
**File**: `src/flutter_app/lib/models/models.dart`
**Changes**: Add `AiStatus` enum.

#### 2. Update Task and Subtask Models
**File**: `src/flutter_app/lib/models/models.dart`
**Changes**: Add `aiStatus` field with default value.

#### 3. Update Isar Schema
**File**: `src/flutter_app/lib/data/schema/isar_models.dart`
**Changes**: Add `aiStatus` (String) to `IsarTask` and `IsarSubtask`.

#### 4. Update Repository Mapping
**File**: `src/flutter_app/lib/data/repository/isar_storage_repository.dart`
**Changes**: Update mapping logic between domain models and Isar.

### Success Criteria:
#### Automated Verification:
- [ ] Run `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Verify no build errors.

---

## Phase 2: UI Implementation
### Overview
Add the AI status button to the task list.

### Changes Required:
#### 1. Update EditableItem Model
**File**: `src/flutter_app/lib/ui/widgets/editable_column.dart`
**Changes**: Add `aiStatus` to `EditableItem`.

#### 2. Update EditableItemWidget
**File**: `src/flutter_app/lib/ui/widgets/editable_item_widget.dart`
**Changes**: 
- Add a status button next to the checkbox.
- Use different icons/colors for each status:
  - `notReady`: Gray circle/pause
  - `ready`: Green play/circle
  - `inProgress`: Blue pulse/spinner
  - `done`: Checkmark in a double circle? Or just green filled.
- Implement click handler to cycle through states.

### Success Criteria:
#### Manual Verification:
- [ ] See the new button in the task list.
- [ ] Verify clicking the button cycles through states.
- [ ] Verify the button look and feel matches the app design.

---

## Phase 3: Logic and MCP Integration
### Overview
Connect the UI to data persistence and expose it to MCP.

### Changes Required:
#### 1. Update DataService
**File**: `src/flutter_app/lib/services/data_service.dart`
**Changes**:
- Add `setAiStatus(String itemId, AiStatus status)` method.
- If status is `done`, call `setItemStatus(itemId, true)`.

#### 2. Create SetAiStatusTool
**File**: `src/flutter_app/lib/ai_tools/implementations/set_ai_status_tool.dart`
**Changes**: Implement the tool to update AI status.

#### 3. Register Tool
**File**: `src/flutter_app/lib/ai_tools/tool_registry.dart`
**Changes**: Register the new tool.

#### 4. Update Tool Definitions
**File**: `src/flutter_app/lib/ai_tools/tool_definitions.dart`
**Changes**: Update `get_projects` and add `set_ai_status`.

### Success Criteria:
#### Automated Verification:
- [ ] Test the new tool via MCP.
- [ ] Verify `get_projects` returns the `aiStatus`.

---

## Testing Strategy
### Unit Tests:
- Test the `DataService.setAiStatus` logic and its side effects on `isCompleted`.
### Manual Testing Steps:
1. Open the app.
2. Create a task.
3. Cycle through AI statuses using the new button.
4. Set AI status to "Done" and verify the checkbox gets checked.
5. Use Cursor/MCP to set AI status and verify the UI updates.

## References
- Ticket: N/A
- Similar implementation: `update_notes` tool.



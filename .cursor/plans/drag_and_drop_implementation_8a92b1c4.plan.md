---
name: Drag and Drop Implementation
overview: Enable drag-and-drop reordering for Projects, Tasks, and Subtasks to improve organization capabilities.
todos:
  - id: refactor-editable-column
    content: Refactor `EditableColumn` to support `ReorderableListView`, use unique keys (IDs), and accept a header widget.
    status: pending
  - id: data-service-reorder
    content: Add reorder methods to `DataService` and immutable model updates.
    status: pending
  - id: integrate-ui
    content: Update `MyApp` to use the new `EditableColumn` with reordering logic and handle the "AI Assistant" item as a header.
    status: pending
  - id: verify-reorder
    content: Verify reordering works for all three columns and persists (in memory).
    status: pending
---

# Drag and Drop Implementation Plan

## Goal
Allow users to reorder Projects, Tasks, and Subtasks using drag-and-drop, similar to "Things 3".

## Architecture Changes

### 1. `EditableColumn` Refactor
**File**: `src/flutter_app/lib/ui/widgets/editable_column.dart`

*   **Data Structure**: Change `items` input from `List<String>` to `List<EditableItem>`, where `EditableItem` contains:
    ```dart
    class EditableItem {
      final String id;
      final String text;
      final bool isCompleted;
      EditableItem({required this.id, required this.text, this.isCompleted = false});
    }
    ```
    This ensures we have stable IDs for `Key` generation, which is critical for `ReorderableListView`.

*   **Widget**: Replace `ListView.builder` with `ReorderableListView.builder`.
    *   Add `onReorder: (int oldIndex, int newIndex)` callback.
    *   Add `Widget? header` parameter to handle the "AI Assistant" item (for Projects column) so it scrolls with the list but isn't reorderable.
    *   **Drag Handle**: Add a `ReorderableDragStartListener` wrapping a drag handle icon (e.g., `Icons.drag_handle`) or the whole row. For desktop, a specific handle is often better to avoid conflict with text selection.

*   **State Management**:
    *   Update local `_controllers`, `_focusNodes`, etc., when `onReorder` is called (or rely on parent rebuild). *Better approach*: Rely on parent rebuild. If parent updates the list order, `didUpdateWidget` will resync. However, `ReorderableListView` expects the list to change immediately.

### 2. Data Service Updates
**File**: `src/flutter_app/lib/services/data_service.dart`

*   Add methods:
    *   `reorderProjects(int oldIndex, int newIndex)`
    *   `reorderTasks(String projectId, int oldIndex, int newIndex)`
    *   `reorderSubtasks(String taskId, int oldIndex, int newIndex)`
*   **Implementation**:
    *   Clone the list.
    *   Remove at `oldIndex`.
    *   Insert at `newIndex` (adjusting for removal).
    *   Update state.

### 3. UI Integration
**File**: `src/flutter_app/lib/app.dart`

*   **Projects Column**:
    *   Pass "AI Assistant" widget as `header`.
    *   Pass the rest of projects as `items`.
    *   Implement `onReorder` calling `dataService.reorderProjects`.

*   **Tasks/Subtasks Columns**:
    *   Pass `items` and implement `onReorder`.

## Implementation Steps

1.  **Update DataService**: Implement the logic to move items in the immutable lists.
2.  **Refactor EditableColumn**: Change to `ReorderableListView`, support `EditableItem` for keys, and add `header`.
3.  **Wire up MyApp**: Adapt the `EditableColumn` calls.

## Verification
*   Drag a project to a new position. Verify it stays there.
*   Drag a task. Verify it stays.
*   Ensure "AI Assistant" stays at the top and cannot be dragged.
*   Check that text focus and selection still work (using handle for drag).

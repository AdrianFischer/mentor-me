# Plan to Fix MCP Workflow Test

## Architecture & Workflow
The testing architecture leverages `flutter_test` to instantiate MCP tools directly against a `DataService` backed by a `TestFileSystemService`. This allows for rapid, headless verification of tool logic and data persistence without needing a full MCP server or manual intervention.

**Workflow:**
1.  Make changes to tool implementations (`app/lib/ai_tools/implementations/`).
2.  Run `flutter test app/test/full_workflow_mcp_test.dart`.
3.  Analyze output and iterate.

## Fix Plan
The initial creation of `full_workflow_mcp_test.dart` blindly cast return values to `String`. Investigation reveals that `AddProjectTool`, `AddTaskTool`, and `AddSubtaskTool` return `Map<String, dynamic>` containing the ID.

### Steps:
1.  **Fix Type Casting**: 
    -   Update `add_project_tool` call to extract `project_id` from the result Map.
    -   Update `add_task_tool` call to extract `task_id` from the result Map.
    -   Update `add_subtask_tool` call to extract `subtask_id` from the result Map.
2.  **Verify Logic**:
    -   Run the test.
    -   If `delete_item_tool` fails (due to file handling), implement robust deletion check or data service fix.
3.  **Finalize**: Ensure test passes 100%.

# Work

description: Automatically finds "Ready" items from the Flutter app, creates a plan, and executes the work until completion. Continuously updates task/subtask notes and status throughout the process.

## PART I - DISCOVERY

1. **Fetch Project State**
   - Call `mcp_flutterApp_get_projects` to retrieve the full project tree with all tasks and subtasks.

2. **Locate Ready Items**
   - Recursively search through all projects, tasks, and subtasks for any item where `aiStatus` equals `"ready"`.
   - If no items are found:
     - Respond: "No items with status 'Ready' found."
     - Terminate.
   - If multiple items are found:
     - Present the list to the user for selection, OR
     - Select the first item found (or highest priority if explicitly prioritized).
   - Announce: "Found ready item: [Title] (ID: [id]). Starting work."

## PART II - PLANNING

1. **Context Gathering**
   - Read the item's `notes` field for any instructions or context.
   - If it's a subtask, also read the parent task's `notes` for additional context.
   - Gather any related files or documentation mentioned in the notes.

2. **Plan Creation**
   - If the task is complex (requires multiple steps) or lacks subtasks:
     - **Implicitly invoke `/create-plan` workflow** to generate a detailed implementation plan.
     - Create the plan file in `thoughts/shared/plans/` following the standard format.
     - If subtasks don't exist, create them using `mcp_flutterApp_add_subtask` based on the plan phases.
   - If subtasks already exist:
     - Review them to ensure they cover the full scope.
     - Update or add subtasks as needed.

3. **Update Notes**
   - Call `mcp_flutterApp_update_notes` with initial status:
     ```
     Status: 🔄 Starting Work
     Last Updated: [Current Date]
     Plan: [Brief description of approach]
     Next: [First step to execute]
     ```

## PART III - EXECUTION LOOP

1. **Set Status to In Progress**
   - Call `mcp_flutterApp_set_ai_status` with `item_id` and `status: "inProgress"`.

2. **Execute Subtasks Sequentially**
   - For each subtask (or the main task if no subtasks):
     - **Work on the subtask:**
       - Perform necessary code edits, file operations, searches, or other actions.
       - Use appropriate tools (read_file, write, search_replace, codebase_search, etc.).
     - **Update Progress:**
       - After each significant step, call `mcp_flutterApp_update_notes` on the item with:
         ```
         Status: 🔄 In Progress
         Last Updated: [Date]
         Completed: [What was just done]
         Next: [What's next]
         ```
     - **Mark Subtask Complete:**
       - When a subtask is finished, call `mcp_flutterApp_update_item_status` with `is_completed: true`.

3. **Continuous Updates**
   - Keep the item's notes updated after every major milestone.
   - Update parent task notes if working on a subtask.
   - Maintain transparency about progress and any blockers.

## PART IV - COMPLETION

1. **Final Verification**
   - Verify all acceptance criteria are met.
   - Ensure all subtasks are marked as completed.
   - Check that the work matches the plan (if one was created).

2. **Mark as Done**
   - Call `mcp_flutterApp_set_ai_status` with `item_id` and `status: "done"`.
   - This will automatically mark the item as completed (checkbox checked).

3. **Final Notes Update**
   - Call `mcp_flutterApp_update_notes` with completion summary:
     ```
     Status: ✅ Complete
     Last Updated: [Date]
     Summary: [What was accomplished]
     - [Key achievements]
     - [Files changed/created]
     - [Tests/verification completed]
     ```

## CONSTRAINTS & GUIDELINES

- **Autonomy**: Items marked as "Ready" imply authorization to proceed. Do not ask for permission for every small step.
- **Transparency**: Always keep notes updated. The Flutter app notes are the primary dashboard for progress visibility.
- **Quality**: Follow the same standards as manual work. Don't rush; ensure code quality and proper testing.
- **Error Handling**: If you encounter blockers or errors, update the notes with the issue and pause for user input if necessary.
- **Scope**: Work only on the selected item. Don't expand scope unless explicitly requested.

## NOTES

- Use `mcp_flutterApp_*` tools for all Flutter app interactions.
- Follow the same patterns used in the "Implement AI Agent Status Button" task as a reference.
- If the task requires external dependencies or setup, document this in the notes.


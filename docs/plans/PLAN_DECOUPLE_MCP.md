# Plan: Decouple MCP - Move Task Logic to Node.js Backend

## 1. Goal & Rationale
Currently, the Node.js Agent (Brain) relies on the Flutter App running an embedded MCP Server to read and write task data. If the app is closed, the agent crashes with `ECONNREFUSED`. 
The goal of this architectural shift is to make the Node.js agent fully autonomous and "headless". It will interact directly with the local Markdown files using its own `data_service.js` and `markdown_parser.js`. 

**Benefits:**
- **Offline Capability:** The Telegram Bot and background Routines (Watchdog) can manage tasks 24/7, even when the Flutter UI is closed.
- **Resilience:** Eliminates the brittle HTTP SSE network dependency (`localhost:8081`) between the agent and the app.
- **Separation of Concerns:** The Flutter App becomes a pure "View" (reacting to file changes), while the Node.js backend handles the true "Brain" and "Model" mutations.

## 2. Current Architecture vs. Target Architecture
*   **Current:** Agent receives Telegram message -> Asks Flutter via MCP (`get_projects`) -> Flutter reads memory/disk -> Flutter replies -> Agent makes decision -> Agent asks Flutter via MCP (`add_task`) -> Flutter writes to memory and disk.
*   **Target:** Agent receives Telegram message -> Agent reads disk directly (`data_service.getProjects()`) -> Agent makes decision -> Agent writes to disk directly (`data_service.addTask()`) -> Flutter File Watcher detects change and updates UI automatically.

## 3. Step-by-Step Implementation Plan

### Phase 1: Graceful Degradation & Stability (Immediate Fix)
- [x] Fix the `ECONNREFUSED` crash in `agent.js` by wrapping `mcp.discoverTools()` in a try/catch block.
- [x] Ensure the agent can still respond conversationally via Telegram even if no tools (or only partial tools) are available.
- [x] Ensure `mcp.test.js` and `agent_errors.test.js` pass with the graceful failure logic.

### Phase 2: Porting "Read" Tools to Node.js
We will create a new tool registry in Node.js (e.g., `task_tools.js`) that directly uses `data_service.js`.
- [x] Implement `get_projects` in Node.js.
- [x] Implement `get_task` in Node.js.
- [x] Implement `list_todos_by_status` in Node.js.
- [x] Write unit tests for the new Node.js "Read" tools.

### Phase 3: Porting "Write" Tools to Node.js
These tools must carefully modify the AST/Markdown and save it back to disk without corrupting existing structures.
- [x] Implement `add_project` in Node.js.
- [x] Implement `add_task` & `add_subtask` in Node.js.
- [x] Implement `update_todo_by_index` & `update_item_name` in Node.js.
- [x] Implement `set_item_status` in Node.js.
- [x] Implement `delete_item` in Node.js.

### Phase 4: Flutter File Watcher Hardening ("Sync Stability")
Since the Node.js agent will now be aggressively modifying files on disk behind the Flutter app's back, the Flutter app's File Watcher must be bulletproof.
- [x] Review `project_service.dart` or the relevant persistence layer in Flutter.
- [x] Ensure changes made externally by Node.js trigger a seamless Riverpod state update without UI stuttering or resetting user scroll position.
- [x] Ensure debouncing logic prevents infinite loops (Flutter writes -> Node sees -> Node writes -> Flutter sees).

### Phase 5: Handling UI-Specific Tools & Deprecation
Some tools (like `set_ai_status`) only make sense when the app is open, as they trigger UI animations.
- [x] Refactor the Node.js agent to handle "Optional MCP": It will attempt to connect to Flutter purely for UI triggers (`set_ai_status`, `navigate_to_task`), but will not rely on it for data.
- [x] Deprecate and remove the redundant data tools (`get_projects`, `add_task`, etc.) from the Dart `ToolRegistry` (`app/lib/ai_tools/implementations/`).
- [x] Clean up legacy MCP code in both codebases.

## 4. Risks & Considerations
- **Concurrency:** If the user is actively typing in the Flutter app while the Telegram agent modifies the same file, we need a strategy to merge or prioritize changes (Local-first strategy).
- **Markdown Parsing Parity:** The Node.js `markdown_parser.js` must be 100% compatible with the Dart parser to ensure files aren't formatted differently depending on who edits them.
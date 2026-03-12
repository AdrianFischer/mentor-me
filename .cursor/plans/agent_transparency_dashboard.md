# Plan: Agent & Routine Transparency Dashboard

**IMPORTANT NOTICE**: This plan document is used as a communication tool across multiple different AI agents and humans. Therefore, it MUST be continuously updated. Every relevant file, every piece of relevant information, and every learning MUST be documented in this file. NEVER delete any information or steps from this plan. A human or an AI agent has to know EXACTLY the state of this plan at all times to continue the work.

---

## 1. Understanding the Goal
The objective is to increase transparency regarding what the system's various autonomous entities—specifically **Agents, Subagents, and Routines**—are currently working on. The user wants to know if they are running right now, what their status is, and suggests a dashboard as a potential solution. 

## 2. Investigation & Analysis

### Current State
Based on the codebase analysis, there are two distinct types of autonomous work happening:

1.  **Background Routines (Watchdog):**
    *   Managed by `agent/watchdog.js` and `agent/routine_runner.js`.
    *   They run as detached subprocesses (`gemini-cli`).
    *   **State:** Active routines and their PIDs are tracked in `logs/routines/active_tasks.json`. Telemetry (token usage) is in `logs/routines/telemetry.json`.
    *   **Logs:** Detailed logs for each run are written to `logs/routines/<routine_name>_<timestamp>.log`.

2.  **Task-Based Subagents (Flutter App/MCP):**
    *   Triggered from the Flutter app UI.
    *   **State:** The state is persisted in the local Markdown files (within `data/todos/` and `data/knowledge/`) using the `aiStatus` frontmatter property (e.g., `notReady`, `ready`, `inProgress`, `done`).
    *   Can be queried via the MCP server (`mcp_flutterApp_list_todos_by_status` or `get_projects`).

3.  **Existing Dashboards:**
    *   There is already a local web server running at `agent/dashboard.js` (port 8082). Currently, it serves `agent/public/index.html` which is exclusively a **PR Test Dashboard** fetching data via GitHub tools.

### Key Questions Addressed
*   *How do we know a routine is running?* We check `logs/routines/active_tasks.json` and verify the PID.
*   *How do we know a subagent is running?* We query the Flutter app via MCP for items with `aiStatus: inProgress`.
*   *Where should this be displayed?* Given an existing dashboard infra exists (`agent/dashboard.js`), extending it is the fastest route, though native Flutter UI integration is also a strong long-term option.

## 3. Proposed Strategic Approach

We will build a unified **System Transparency Dashboard** by extending the existing local web server (`agent/dashboard.js`).

### Phase 1: Backend Data Aggregation (Node.js) - [COMPLETED]
1.  **Extend `agent/dashboard.js`:** Add a new API endpoint (e.g., `/api/system-status`). [COMPLETED]
2.  **Routines Source:** Read and parse `logs/routines/active_tasks.json`. Map PIDs to their start times and log files. [COMPLETED]
3.  **Subagents Source:** Query the local MCP server (running on the Flutter App) or parse the local markdown files directly to find any tasks or subtasks where `aiStatus == 'inProgress'`. [COMPLETED]
4.  **Telemetry/History:** Optionally read `logs/routines/telemetry.json` to show recently completed routines and their token usage to prove "work was done." [COMPLETED]

### Phase 2: Frontend Dashboard Expansion (HTML/JS) - [COMPLETED]
1.  **Update `agent/public/index.html`:** Refactor the UI to have tabs or a split view: "PRs" and "Active Agents". [COMPLETED]
2.  **Active Agents View:** 
    *   Display a list of currently running **Background Routines** with a live timer (derived from `start_time`). [COMPLETED]
    *   Display a list of currently running **Task Subagents**, linking back to the task title and project. [COMPLETED]
3.  **Auto-Refresh:** Implement a lightweight polling mechanism (e.g., every 5-10 seconds) on the frontend to keep the Active Agents view up to date without manual refreshes. [COMPLETED]

### Phase 3: Session Details & AI Chat - [COMPLETED]
1.  **Backend Updates:** Expose `/api/logs` to fetch session logs, and `/api/chat` to allow questioning the agent about those logs. Inject the Gemini dependency into `DashboardService`. Modify `routine_runner.js` to embed the `logFile` path within the telemetry JSON. [COMPLETED]
2.  **Frontend Updates:** Convert telemetry history items into clickable elements. Upon clicking, open a modal displaying a slice of the log and providing an interactive chat window connecting to `/api/chat`. [COMPLETED]

### Phase 4: Flutter App Integration (Optional/Future)
1.  Once the web dashboard proves the concept, introduce a global "Active Agents" indicator in the Flutter application's Top App Bar or Sidebar, showing a count of running routines and subagents.

## 4. Verification Strategy
*   **Routine Test:** Manually trigger a long-running routine (e.g., using a sleep command in a test routine) and verify it appears on the dashboard with the correct start time.
*   **Subagent Test:** Set a task's `aiStatus` to `inProgress` in the Flutter app and verify the dashboard picks it up immediately.
*   **Zombie Process Test:** If a routine crashes and leaves a stale entry in `active_tasks.json` without a running PID, the backend logic should detect this and automatically clean it up or mark it as "Dead".

## 5. Anticipated Challenges & Considerations
*   **Stale Data:** `active_tasks.json` might not be cleaned up if the Node process is forcefully killed. The backend endpoint MUST verify if the recorded `pid` is actually still running (`process.kill(pid, 0)` in Node) before sending it to the frontend.
*   **MCP Availability:** If the Flutter app (which hosts the MCP server) is closed, the query for active subagents will fail. The dashboard needs graceful error handling ("App offline - cannot fetch task agents") rather than crashing.
*   **Log Parsing Performance:** Avoid reading massive log files entirely into memory if implementing a "tail logs" feature. Use stream reading or `fs.readSync` to only grab the last few kilobytes.

## 6. Log / Learnings
*   *(2026-03-12)* - Discovered that the app uses `logs/routines/active_tasks.json` for watchdog routines.
*   *(2026-03-12)* - Discovered that `mcp_flutterApp_get_projects` or `mcp_flutterApp_list_todos_by_status` can be used to query active UI tasks.
*   *(2026-03-12)* - **Implemented Phase 1 & 2**: Added `/api/system-status` in `agent/dashboard.js` which performs live checks against `active_tasks.json` with `process.kill(pid, 0)` checking. Also queries the dynamic MCP port from `~/.assisted_intelligence/mcp_port`. Re-wrote `agent/public/index.html` to include a split-tab UI (System vs PR Tests) with auto-refresh every 5 seconds for live status.
*   *(2026-03-12)* - **Improved Agent Resilience**: Modified `agent/index.js` to start the Dashboard Service *before* attempting the MCP connection. Also wrapped the MCP connection loop in a try/catch so the agent (and dashboard) continues running even if the Flutter app is not reachable.
*   *(2026-03-12)* - **Implemented Phase 3 (Session Details & Chat)**: Added click-to-open modals on telemetry items in the dashboard. The backend `DashboardService` now receives `gemini` in its constructor to provide a quick `/api/chat` route to let users interrogate specific logs from completed background routines. Updated `routine_runner.js` to save the absolute log path directly inside `telemetry.json` for easier access by the dashboard.

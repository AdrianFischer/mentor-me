---

id: 93f225b1-2c65-4f4c-8cbf-3cab0ac6c615

version: 1

---


# This App


- [x] Integrate Voice Memos with the App <!-- id: 9fe2df65-e700-4ef9-99ef-b85226f8dd8c -->

- [x] Persist last execution time for routines <!-- id: d00e1b07-512e-4fe3-be76-5c17cbf985d4 -->
  Note down in the routine when it was executed last. This ensures that restarting the agent doesn't automatically trigger all routines, but only those that are due for execution based on their schedule.

- [x] Improve Flutter app sync stability <!-- id: df3ef8d8-bac3-4eee-8808-90b0bd096a3a -->

- [x] Refactor AgentBrain (agent/agent.js) for modularity <!-- id: 2129ced0-d590-435d-9354-efcf5c31d2bf -->
  **WHY it should be refactored:**
  1. Violation of the Single Responsibility Principle (SRP): AgentBrain currently manages two completely distinct domains (AI loop and File System CRUD operations for Autonomous Routines).
  2. Hardcoded Domain Coupling: The JSON schemas for routine management tools are hardcoded directly inside `_gatherTools()`.
  3. Test Code Pollution: The file contains a `processInput()` method explicitly bypassing the LLM for tests. Production code should not harbor test mocks.
  - [x] 1. Extract a RoutinesManager Module (move fs operations) <!-- id: c7e01d91-78ca-4b41-88be-367fa94383ec -->
  - [x] 2. Expose Local Tools Dynamically (add getTools() and execute()) <!-- id: 4df24c52-f10a-4a77-9b07-2b4719328656 -->
  - [x] 3. Refactor AgentBrain to Delegate (_gatherTools and _executeTool) <!-- id: 4e30fc02-3025-4e15-928b-e1f37ff93902 -->
  - [x] 4. Remove Test Artifacts (delete processInput, mock gemini service) <!-- id: 1e2caecd-40f6-4da1-9945-0e8146bb2a5c -->

- [x] Fix Flutter app state sync for completed projects <!-- id: a3b56e9c-d4c3-4a92-90e3-2709f64d03f8 -->
  **Problem Description:**\nProjects marked as completed on the backend are not updating to reflect their completed status in the Flutter app UI.\n\n**Current State:**\n- There is no manual pull-to-refresh implemented.\n- There is no real-time synchronization or local cache invalidation occurring when a project's `is_completed` status changes via the API.\n\n**Agent Action Required:**\n- Investigate the local caching and state management logic in the Flutter app.\n- Implement a reliable mechanism (such as WebSockets, polling, or proper local state invalidation) to ensure UI updates seamlessly when projects are completed.\n- Add manual refresh capabilities if appropriate.

- [x] Oft werden Leerzeichen in Tasks nicht getippt. <!-- id: 621f7e07-b385-429f-b47c-ff07d549f203 -->

- [x] Allow to use websearch in the background agents that operate on the routines <!-- id: 26cf2f38-0a3a-4741-a419-c11c597ad24d -->
  I would like to give them access to a single file / folder ONLY AND to give them websearch capabilities through the gemini cli

- [x] Add feedback loop for AI agent to verify created tasks and check routines <!-- id: 7fb4688f-1764-43b4-a5ef-79bfc7d979e2 -->
  The AI agent needs a reliable way to query the database and background routine manager to quickly verify if tasks/subtasks have been successfully committed and if routines are active. Currently, checking the routines or pulling task IDs sometimes times out or lacks definitive confirmation. This needs to be improved so the AI doesn't have to guess or assume the state of backend systems for the user.

- [x] Improve chat UI: Edit 'Discovering tools...' message instead of sending a new one <!-- id: 28d6306b-956e-45b0-bde2-4c273c74f547 -->
  Currently, when the AI agent triggers tools, the chat UI creates a 'Discovering tools...' message, and then appends a second message for the actual progress updates. Refactor the backend/frontend message handling so that the initial 'Discovering tools...' message is updated directly rather than creating a second message. \n\n**BUG REPORT:** The previous fix didn't work. The UI still shows two messages! Please investigate why the previous fix failed and correct the state management/message merging logic in Flutter/backend.

- [x] Implement on-demand triggering for background routines <!-- id: b6302f41-9e4c-420c-9215-594904adff5b -->
  Currently, forcing a routine to run requires temporarily changing its execution frequency (e.g., to 15 seconds) and then changing it back. This feels hacky. We need an API endpoint or a mechanism to directly trigger a specific routine's execution immediately, bypassing its scheduled interval, without modifying the underlying configuration file.

- [x] Improve Watchdog timeout logic for background routines <!-- id: d6661e90-a92a-4ee8-b2c4-60add7ff6140 -->
  **Bug Report:** The Flutter MCP Auto-Worker routine was repeatedly killed by the Watchdog due to a timeout (`[TIMEOUT_ERROR] Process killed by Watchdog due to timeout`). Investigate the Watchdog behavior—perhaps prevent spawning overlapping routine instances if the previous one is still actively working, or gracefully handle AI task timeouts so they don't abruptly crash. I've temporarily bumped its explicit timeout limit to 10 minutes (600s), but the core mechanism needs an upgrade.


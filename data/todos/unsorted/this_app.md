---

id: 93f225b1-2c65-4f4c-8cbf-3cab0ac6c615

version: 1

---


# This App


- [x] Integrate Voice Memos with the App <!-- id: 9fe2df65-e700-4ef9-99ef-b85226f8dd8c -->

- [x] Persist last execution time for routines <!-- id: d00e1b07-512e-4fe3-be76-5c17cbf985d4 -->
  Note down in the routine when it was executed last. This ensures that restarting the agent doesn't automatically trigger all routines, but only those that are due for execution based on their schedule.

- [ ] Improve Flutter app sync stability <!-- id: df3ef8d8-bac3-4eee-8808-90b0bd096a3a -->

- [x] Refactor AgentBrain (agent/agent.js) for modularity <!-- id: 2129ced0-d590-435d-9354-efcf5c31d2bf -->
  **WHY it should be refactored:**
  1. Violation of the Single Responsibility Principle (SRP): AgentBrain currently manages two completely distinct domains (AI loop and File System CRUD operations for Autonomous Routines).
  2. Hardcoded Domain Coupling: The JSON schemas for routine management tools are hardcoded directly inside `_gatherTools()`.
  3. Test Code Pollution: The file contains a `processInput()` method explicitly bypassing the LLM for tests. Production code should not harbor test mocks.
  - [x] 1. Extract a RoutinesManager Module (move fs operations) <!-- id: c7e01d91-78ca-4b41-88be-367fa94383ec -->
  - [x] 2. Expose Local Tools Dynamically (add getTools() and execute()) <!-- id: 4df24c52-f10a-4a77-9b07-2b4719328656 -->
  - [x] 3. Refactor AgentBrain to Delegate (_gatherTools and _executeTool) <!-- id: 4e30fc02-3025-4e15-928b-e1f37ff93902 -->
  - [x] 4. Remove Test Artifacts (delete processInput, mock gemini service) <!-- id: 1e2caecd-40f6-4da1-9945-0e8146bb2a5c -->


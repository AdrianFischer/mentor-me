# Strategic Plan: Agent Enhancements V2 (The Proactive Assistant)

This plan document is a communication tool across multiple different agents. Therefore, every relevant file, every relevant information, and every learning MUST be documented in this file. This file must represent the current state of the effort at all times.

## 1. Understanding the Goal

The goal is to evolve the "Assisted Intelligence" agent from a reactive tool-caller into a proactive, reliable, and context-aware "Senior Executive Assistant." We will address the five most critical areas for improvement identified during real-world usage.

**The 5 Improvements:**
1.  **Session Persistence:** Save chat history to disk so the agent remembers previous turns after a restart.
2.  **Self-Verification Loop:** The agent will proactively verify its actions (e.g., checking if a task was actually added) before confirming to the user.
3.  **Knowledge Base Search (RAG):** Allow the agent to search local Markdown files (`data/knowledge`) for project-specific context (e.g., "Who is Marco?").
4.  **Graceful Error Recovery:** Better handling and user-friendly explanation of tool failures (e.g., MCP server timeouts).
5.  **Interactive Buttons (UX):** Use Telegram's inline keyboards for common follow-up actions (e.g., "Mark as Done", "Add Note").

## 2. Investigation & Analysis

### Current State
- **History:** Volatile (in-memory only). Lost on process exit.
- **Verification:** None. The agent assumes `callTool` success means the desired state was reached.
- **Knowledge:** Limited to the system prompt and current chat history.
- **Error Handling:** Basic `try/catch` that returns a generic "something went wrong" message.
- **UI:** Purely text-based.

### Key Files
- `agent/agent.js`: The "Brain" orchestrating the flow.
- `agent/gemini.js`: Manages history and model interaction.
- `agent/telegram.js`: Entry point for user interaction and UI.
- `app/lib/ai_tools/`: Source of truth for available actions.

## 3. Proposed Strategic Approach

### Phase 1: Session Persistence (`agent/gemini.js` & `agent/config.js`)
- **Objective**: Maintain context across restarts.
- **Actions**:
    - Implement `HistoryStorage` class (simple JSON file in `agent/data/sessions.json`).
    - Update `GeminiService` to load history on startup and save it after every Turn.
    - Key sessions by `chatId` (Telegram) to support multi-user isolation.

### Phase 2: Knowledge Search Tool (`agent/agent.js`)
- **Objective**: Connect the agent to the project's documentation.
- **Actions**:
    - Add a "Internal Tool" (or new MCP tool) `search_knowledge` that greps through `data/knowledge/*.md`.
    - Update the system instruction to encourage searching when the user mentions unknown entities.

### Phase 3: Verification & Self-Correction (`agent/agent.js`)
- **Objective**: Eliminate "Hallucinated Success."
- **Actions**:
    - Create a `verify_state(item_id)` tool (or reuse `get_project`/`get_task`).
    - Update `AgentBrain` logic: After a mutation tool (e.g., `add_task`), the brain should automatically trigger a verification turn if the model is unsure or if the task is critical.

### Phase 4: Graceful Error Recovery
- **Objective**: Professional handling of technical failures.
- **Actions**:
    - Update `mcp.js` to return detailed error codes (TIMEOUT, AUTH, NOT_FOUND).
    - Update `AgentBrain` to explain the situation to the user (e.g., "I've tried to add the task, but the main app is currently not responding. I'll remember this and try again when it's back.")

### Phase 5: Interactive UI (`agent/telegram.js`)
- **Objective**: Reduce typing for the user.
- **Actions**:
    - Update `safeReply` to support optional `inline_keyboard` parameters.
    - When a task is created, add a [📝 Add Note] and [✅ Done] button to the confirmation message.

## 4. Verification Strategy

### Automated Testing
- **Persistence Test**: Start agent, send message, stop agent, restart, verify history is present.
- **Verification Test**: Mock a tool failure and verify the brain detects the state mismatch.
- **Error Handling Test**: Simulate MCP timeout and verify the user receives a helpful explanation.

### Manual Verification
- Ask "Who is Marco?" and verify the agent searches the knowledge base.
- Send a voice memo to add a task, then check the app to see if it's there.
- Interact with a Telegram button and verify the action is performed.

## 5. Anticipated Challenges & Considerations
- **Concurrency**: Multi-user persistence needs careful file locking or a simple database (SQLite).
- **Latency**: Adding a verification turn adds one more AI inference (~2-3s).
- **Token Usage**: Persistent history grows over time; need to maintain the sliding window strictly.

## 6. Relevant Information & Findings (To be updated)
- [2026-03-06] Initial plan created.

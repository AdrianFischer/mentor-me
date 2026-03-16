# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Assisted Intelligence** is a keyboard-driven task management application with deep AI integration. It operates on a **local-first, file-first** architecture where Markdown files in the user's data directory are the primary source of truth. The system combines:

- **Frontend:** Flutter (Dart) targeting macOS, iOS, and Web
- **Backend:** Firebase Functions (Node.js/TypeScript) with Google Gemini AI
- **AI Agent:** Autonomous Node.js agent with MCP protocol support, Telegram integration, and scheduled routines
- **State Management:** Riverpod for in-memory state, with write-behind persistence to Markdown files

The app enables users to manage tasks, projects, and strategic goals while leveraging AI for task breakdown, verification, and autonomous background work.

## Common Commands

### Flutter App (`app/`)

```bash
# Get dependencies and run on macOS
cd app && flutter pub get && flutter run -d macos

# Run tests
cd app && flutter test

# Run web version
cd app && flutter run -d web

# Build release
cd app && flutter build macos

# Generate freezed models and json serialization
cd app && flutter pub run build_runner build --delete-conflicting-outputs
```

### Agent (`agent/`)

```bash
# Install dependencies
cd agent && npm install

# Run tests
cd agent && npm test

# Run main agent CLI (processes stdin)
cd agent && node index.js

# Run Telegram bot
cd agent && node telegram.js

# Check active tasks and logs
cd agent && node scripts/list_open_tasks.cjs

# Test routine runner (processes JSON from logs/routines)
cd agent && node scripts/test_runner.js
```

### Backend Firebase Functions (`backend/`)

```bash
# Install dependencies
cd backend && npm install

# Build TypeScript
cd backend && npm run build

# Run emulator locally
cd backend && npm run serve

# Deploy to Firebase
cd backend && npm run deploy

# View logs
cd backend && npm run logs
```

## Architecture Overview

### Data Flow & Persistence

1. **Markdown Files (Source of Truth):** Users' todo items live in `data/todos/` as `.md` files with YAML frontmatter (title, description, status, etc.).
2. **Isar DB & Memory State:** The Flutter app parses these files on startup, stores data in Isar, and maintains in-memory Riverpod state for instant UI responsiveness.
3. **Write-Behind Strategy:** When the UI updates state, changes are committed to Isar and written back to Markdown files asynchronously.
4. **Agent Interaction:** The autonomous Node.js agent discovers the running app via MCP (embedded HTTP server on port 8081) and can read/write tasks, projects, and routines.

### Key Modules

#### Flutter App (`app/lib/`)
- **`main.dart` / `app.dart`:** Entry points and root widget setup with Riverpod providers.
- **`services/`:** Core business logic including `DataService` (parses Markdown), `AssistantService` (AI integration), `MCPClientService` (communicates with agent), `FileSystemService` (watches for external changes).
- **`providers/`:** Riverpod state management for projects, tasks, and UI state.
- **`models/`:** Dart classes for `Project`, `Task`, `Subtask` (generated with freezed).
- **`ui/`:** Screens and widgets for the keyboard-driven interface.

#### Agent (`agent/`)
- **`agent.js`:** `AgentBrain` class—entry point that orchestrates Gemini API calls, tool discovery, and tool execution.
- **`gemini.js`:** Low-level Gemini API wrapper; handles model selection and tool calling.
- **`telegram.js`:** Telegram bot service; receives messages, calls `AgentBrain.process()`, and replies via HTML format.
- **`routines_manager.js`:** Manages scheduled tasks stored in `data/routines/` JSON files.
- **`routine_runner.js`:** Executes routines as detached child processes; parses JSON telemetry output.
- **`mcp.js`:** MCP client; discovers and caches tools from the running Flutter app.
- **`github_tools.js`:** GitHub API integration (PRs, issues, workflows).
- **`shared_folder_manager.js`:** Sandboxed file I/O and command execution in `data/shared/`.
- **`watchdog.js`:** Daemon that executes routines on schedule and reports results to Telegram.
- **`scripts/`:** Standalone utility/debug scripts (MCP clients, parsers, test harnesses). Not imported by core modules.

#### Data (`data/`)
- **`todos/`:** Markdown task files (source of truth).
- **`routines/`:** JSON routine definitions for scheduled agent tasks.
- **`shared/`:** Sandboxed folder for agent file I/O.
- **`agent/`:** Agent runtime state (chat history).

#### Documentation (`docs/`)
- **`GEMINI.md`:** Agent learnings and future context.
- **`architecture.md`:** System architecture overview.
- **`conductor/`:** Conductor workflow documentation.
- **`plans/`:** Archived plans and research notes.

#### Logs (`logs/`)
- Single canonical log location for all components. Agent logs to `logs/agent.log`, routines to `logs/routines/`.

#### Backend (`backend/src/`)
- Firebase Functions for cloud-based features (placeholder; most logic is in the agent).

### Core Patterns & Conventions

#### State Management (Riverpod)
- All app state flows through Riverpod providers (no direct `setState`).
- Providers for projects, tasks, filters, and assistant conversations.
- Immutable state updates through `.copyWith()` (freezed models).

#### Data Persistence (Markdown ↔ Isar ↔ Memory)
- **Parse:** `DataService.loadProjectsFromMarkdown()` reads `.md` files, extracts YAML frontmatter, and builds Dart objects.
- **Persist:** `FileSystemService` listens for file changes and reloads; UI mutations trigger writes via `FilePersistenceService`.
- **Loop Prevention:** File watchers ignore internal writes (2-second debounce) to prevent infinite update cycles.

#### AI Integration (Gemini + Tools)
- `AssistantService` in the app provides a high-level "chat with AI" interface via the agent's MCP server.
- Agent's `AgentBrain` accepts string (text) or object (`{ audioBase64, mimeType }` for voice) inputs.
- Tools are discovered dynamically (MCP, local routines, GitHub, shared folder).
- Critical: Strip media bytes from chat history after processing to avoid token waste.

#### Telegram Integration (HTML Mode, Typing Indicator)
- Use HTML parse mode (`<b>`, `<i>`, `<code>`) instead of Markdown—it's more reliable.
- Keep typing indicator active during long operations: send `ctx.sendChatAction('typing')` every 4 seconds.
- User security via whitelist: `AUTHORIZED_USER_IDS` in `.env` (discovery mode if empty).

#### Autonomous Routines (Scheduled Tasks)
- Routines are JSON files in `data/routines/` defining schedule, timeout, and context.
- `watchdog.js` spawns detached processes that run the agent CLI with routine context.
- Routine output is parsed for `{ total_tokens, ... }` JSON; `NO_ACTION_TAKEN` responses are silenced.
- Telemetry logged to `logs/routines/telemetry.json` for auditing token usage.

#### Verification-First (Mandatory)
- When an agent mutation completes (e.g., create task), immediately call a GET tool to verify the change before confirming success.
- Critical for task-related tools: use `list_tasks`, `get_project`, etc. to ensure the database reflects the change.
- Log all tool calls and results for debugging.

### API & Communication

#### MCP Server (Flask HTTP Server in Flutter App)
- **Port:** 8081 (configurable)
- **Discovery:** `GET /mcp/tools` → list of available tools
- **Projects:** `GET /projects` → full hierarchy
- **Tasks:** `POST /tasks`, `POST /tasks/<id>/subtasks`, etc.
- **Availability:** Only when Flutter app is running (`flutter run`).

#### Gemini AI API
- Set `GEMINI_API_KEY` in `app/.env` (not committed to git).
- Models: Gemini 1.5 Pro, Gemini 1.5 Flash, Gemini 2.0 Flash (configurable).
- Supports multimodal input: text, images (JPEG/PNG), audio (Opus/OGG).

#### Telegram Bot API
- `TELEGRAM_BOT_TOKEN` and `AUTHORIZED_USER_IDS` in `app/.env`.
- HTTP polling; handlers have a 90-second default timeout (increase to 300s for heavy processing).
- Sends actions via HTML (`text`, `caption`, `parse_mode: 'HTML'`).

## Important Learnings & Patterns

### (from docs/GEMINI.md "Learnings & Future Context")

1. **Multimodal Media Handling:**
   - Strip `inlineData` (both audio and image bytes) from chat history after the initial turn—replace with text placeholders like `[Processed Audio]`.
   - Failure to do so causes massive token waste and latency.

2. **Stable Session Indexing:**
   - Agents prefer stable 1, 2, 3... indices for tasks/projects rather than managing UUIDs directly via voice.

3. **Local-First Priority:**
   - Markdown and Isar DB are the primary stores; Firebase/Cloud sync is optional and secondary.
   - Ensures privacy, speed, and offline operation.

4. **Loop Prevention in File Watchers:**
   - Apply time-based ignoring (2s debounce) *after* file extension filtering but *before* expensive aggregation.
   - Explicitly delete old files by ID before renaming to avoid orphans.

5. **Error Handling & "Final Summary Turn":**
   - If tool execution results in empty response text, the agent should perform a "Final Summary Turn" to force human-friendly output.
   - Avoid robotic output like bare tool names; summarize actions taken.

6. **Continuous Learning:**
   - After complex integrations or discoveries (e.g., "Use HTML for Telegram, not Markdown"), document findings immediately in docs/GEMINI.md.
   - These learnings are the collective memory for all agents.

7. **Efficient Log Monitoring:**
   - Large log files (multi-gigabyte) should be read via `fs.openSync()` / `fs.readSync()` + seeking to EOF, not `fs.readFileSync()`.
   - Ensures near-instant response and low memory overhead.

8. **Timeout Management:**
   - Telegram's default handler timeout: 90 seconds (increase for multimodal processing).
   - Routine execution: mandatory `timeout` field to prevent zombie processes.

## Testing & Verification

### Unit Tests
- **Flutter:** `flutter test` runs all tests in `app/test/`.
- **Agent:** `npm test` in `agent/` runs Vitest suite.

### Integration Testing
- Use dedicated test files in `agent/scripts/` (e.g., `test_runner.js`, `stability_harness.js`) to verify complex sequences (routine parsing, tool execution, log reading).
- Always verify mutations with a subsequent GET tool call.

### Acceptance Criteria (ACs)
- For complex integrations, define a detailed list of ACs and translate them into automated tests *before* implementation.

## Development Workflow

1. **Read & Understand:** Always read the relevant source files before proposing changes.
2. **Test Locally:** Build and test changes locally (Flutter, Agent) before committing.
3. **Verify Mutations:** Use GET tools or test scripts to verify that changes persisted correctly.
4. **Update Docs:** If you discover new patterns or learnings, update docs/GEMINI.md's "Learnings" section.
5. **Log Everything:** Use the structured logger (agent) or print statements for debugging; logs feed into telemetry.

## Environment & Configuration

- **`app/.env`:** Flutter app config (GEMINI_API_KEY, SCREENSHOT_DIR, AUTHORIZED_USER_IDS for Telegram).
- **`.git/`:** Standard Git repo; commit rules enforced via pre-commit hooks if configured.
- **Cursor Rules:** `.cursor/rules/` contains context rules for Cursor IDE integration (personal assistant role, MCP guidelines, task logging).
- **Routines:** `data/routines/` contains JSON definitions for scheduled agent tasks.

## Side Hustle — Warehouse Integration Service

Adrian is building a side business via his UG: an AI-powered integration service for warehouse customers (ERP/SAP/Excel → WMS anbindung). Key context files:

- **Tasks & Strategy:** `data/todos/unsorted/side_hustle.md`
- **Market Research:** `data/shared/side_hustle_market_research.md`
- **Tech Research:** `data/shared/side_hustle_tech_research.md`
- **Mentor Skill:** `/sidehustle` — loads full context and enters mentor mode with 3 personas

Business model: Productized Service (Blueprint Sprint ~2-3k€, Connector ~5-13k€, Retainer monthly). Current phase: Validation (customer interviews).

## Troubleshooting

- **Agent not connecting to app:** Verify Flutter app is running with `flutter run -d macos`; check MCP port in logs.
- **File sync issues:** Examine `FileSystemService` watchers; ensure loop prevention is active (2s debounce).
- **Token wastage in Telegram:** Check that media bytes are stripped from chat history after the first turn.
- **Routine timeouts:** Increase timeout in `data/routines/<routine>.json` if agent processes take longer than expected.
- **Secrets accidentally committed:** Use `git filter-branch` or GitHub's push protection to undo; immediately rotate credentials.

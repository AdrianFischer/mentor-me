# Assisted Intelligence - GEMINI.md

## Project Overview

**Assisted Intelligence** is a keyboard-driven task management application designed for power users. It differentiates itself through deep AI integration, featuring a "Mentor" mode that provides strategic career guidance and autonomous agents that assist with task breakdown and verification.

The application follows a **local-first, file-first** architecture for speed, privacy, and portability. It operates directly on human-readable Markdown files as its primary source of truth, with an in-memory application state for instant UI responsiveness.

## Technical Stack

*   **Frontend:** Flutter (Dart) targeting macOS, iOS, and Web.
*   **Backend:** Firebase Functions (Node.js / TypeScript).
*   **State Management:** Riverpod.
*   **Data Persistence:**
    *   **Primary (Local):** Direct-to-Markdown. The app parses and writes `.md` files in the user's data directory.
    *   **Cloud Sync (Optional):** Firebase Firestore and Storage (for cross-device synchronization and large assets).
*   **AI & Agents:**
    *   **Model:** Google Gemini (via `firebase_ai` and Vertex AI).
    *   **Protocol:** Model Context Protocol (MCP) via `mcp_dart`.
    *   **Integration:** Embedded HTTP server (`shelf`) for Agent-App communication.
*   **Environment:** `flutter_dotenv` for configuration.

## Directory Structure

*   **`app/`**: The main Flutter application source code.
    *   `lib/`: Dart source files.
    *   `test/`: Unit and widget tests.
    *   `bin/`: Entry points for auxiliary scripts or servers (e.g., `mcp_bridge.dart`).
*   **`backend/`**: Firebase Functions implementation.
    *   `src/index.ts`: Main entry point for cloud functions.
*   **`conductor/`**: Product management and architectural documentation.
    *   `product.md`: High-level product goals and feature definitions.
    *   `tech-stack.md`: Detailed technology choices.
    *   `tracks/`: Specific development tracks and plans.
*   **`knowledge_base/`**: Contextual documents, design specs, and research.
*   **`.github/`**: CI/CD workflows and Gemini automation configuration.

## Development & Usage

### Prerequisites
*   Flutter SDK (^3.9.2)
*   Node.js (v20) & npm
*   Firebase CLI

### Setup
1.  **Environment Variables:**
    Create a `.env` file in the `app/` directory (ignored by git):
    ```env
    GEMINI_API_KEY=your_api_key_here
    SCREENSHOT_DIR=/path/to/screenshots
    ```

### Building and Running

**Flutter App:**
```bash
cd app
flutter pub get
flutter run
```
*   To run with fallback configuration if `.env` is missing:
    ```bash
    flutter run --dart-define=GEMINI_API_KEY=your_key
    ```

**Backend (Firebase Functions):**
```bash
cd backend
npm install
npm run build
# To run locally with emulators:
npm run serve
```

**Testing:**
```bash
cd app
flutter test
```

## Key Conventions

*   **State Management:** Use Riverpod for all app state. Avoid `setState` for complex logic.
*   **Data Persistence:** Files are the source of truth. The application uses a write-behind strategy to persist in-memory changes to disk while maintaining responsiveness.
*   **AI Integration:** AI features should be implemented using the `firebase_ai` package.
*   **MCP:** New tools for the AI agent should be exposed via the embedded MCP server setup in the app.
*   **Design:** Follow a minimalist, high-contrast, distraction-free visual style.

## Learnings & Future Context (CRITICAL)

*This section MUST be updated continuously as new insights are discovered. It serves as the collective memory for all agents and collaborators.*

*   **Architecture (Brain vs. View):** The "Intelligent Agent" (Brain) should be hosted as a standalone service (Node.js) separate from the Flutter UI (View). This ensures logic errors do not freeze the UI and allows for independent scaling and debugging.
*   **Local-First Priority:** Initial implementations of AI features (long-term memory, image artifacts) should prioritize local storage (Isar/File System) to ensure privacy and speed. Cloud synchronization should be added as a secondary, optional layer.
*   **Stable Reference Mapping:** Agents require a "Session Index" (stable 1, 2, 3...) to refer to tasks and projects, as managing UUIDs directly via voice/text is inefficient.
*   **MCP Discovery:** The system uses a standard location (`~/.assisted_intelligence/mcp_port`) for port auto-discovery, allowing standalone agents to find the running app instantly.
*   **Test-Driven Specification:** For complex integrations like the Telegram Agent, a detailed list of Acceptance Criteria (ACs) must be defined and translated into automated tests *before* implementation begins.
*   **Empirical Verification (MANDATORY):** Never return a task as "complete" without verifying the logic changes. Every new method or critical sequence (like startup retries) must be exercised via an automated test or a dedicated verification script (e.g., `test_logger.js`).
*   **Secret Management:** Never commit API keys or tokens. Redact immediately and use `.env` files located in the `app/` directory, which are ignored by Git. If a secret is committed, GitHub's Push Protection requires manual unblocking and a potential history rewrite.
*   **Multimodal Media (Direct Processing):** Gemini 1.5+ supports native `.ogg` (Opus) audio and image processing (`image/jpeg`, `image/png`, etc.). To process Telegram media efficiently:
    1.  Download the file from Telegram and convert to a base64 string.
    2.  Send to Gemini as `inlineData` with the appropriate `mimeType`.
    3.  **CRITICAL:** Strip raw `inlineData` (both audio and image) from the chat history after the initial turn (replace with a text placeholder like `[Processed Image]`). Failure to do so causes the media bytes to be resent in every subsequent turn, leading to massive token waste and high latency.
*   **Telegram Reliability (HTML):** Use HTML parse mode for Telegram responses instead of Markdown. It is significantly more reliable and less prone to parsing errors. Supported tags include `<b>`, `<i>`, and `<code>`. Use '•' for bullet points.
*   **Telegram Timeout Constraints:** The `telegraf` library has a default `handlerTimeout` of 90 seconds. For heavy multimodal processing or complex tool-call chains, this MUST be increased (e.g., to 300s/5m) to prevent `TimeoutError` crashes.
*   **Continuous Feedback (Typing Status):** Telegram's "typing" indicator expires after ~5 seconds. To keep it active during long "thinking" sessions, implement a heartbeat that sends `ctx.sendChatAction('typing')` every 4 seconds.
*   **AI Persona (Human-in-the-Loop):** To avoid robotic output (like listing tool names), the agent is configured as a **Senior Executive Assistant**. If tool execution results in an empty response text, the brain should perform a "Final Summary Turn" to force a human-friendly explanation of actions taken.
*   **Unified Brain API:** Use a polymorphic `process(input)` method in the agent brain that accepts either a `string` (text) or an `Object` (audio/image data). This simplifies the interaction layer and makes the system multimodal by default.
*   **Standardized Media Protocol:** Tools should return media in a standardized `media: { imageBase64, mimeType }` object. The Brain should pass this object generically to the interaction layer. This prevents "leaky logic" where the brain needs to know the internal structure of every tool.
*   **Architectural Separation (Rich Objects):** The Brain should return "Semantic Objects" (text + media + metadata). The interaction layer (e.g., `BotService`) is responsible for translating these into platform-specific formats (like Telegram HTML).
*   **Verification-First Mutating:** When the agent adds or updates data, it should proactively verify the change by calling a "Get" tool (e.g., `get_project` or `list_todos`) before confirming success to the user. This eliminates "hallucinated success."
*   **Continuous Learning (The Reflection Step):** Every task MUST conclude with a "Reflect & Document" turn. The agent identifies:
    1.  What unexpected technical hurdle was found?
    2.  What user preference was discovered (e.g., "Use HTML, not Markdown")?
    3.  What architectural pattern should be reused?
    These insights must be committed to `GEMINI.md` immediately.

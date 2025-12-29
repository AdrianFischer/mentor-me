# Project Features & Conventions Matrix

This document serves as a comprehensive registry of all features, architectural conventions, and associated tests for the Assisted Intelligence Flutter Application.

## 1. Core Task Management (Hierarchical UI)

The core application utilizes a 3-column Miller Columns layout for managing nested data.

| Feature | Description | Implementation Details | Associated Tests |
| :--- | :--- | :--- | :--- |
| **Project Column** | First column listing high-level projects. Supports addition, deletion, and selection. | `_buildProjectColumn` in `app.dart`. Uses `EditableColumn`. | `nav_create_cleanup_test.dart`, `widget_test.dart` |
| **Task Column** | Second column listing tasks for the selected project. | `_buildTaskColumn` in `app.dart`. | `nav_create_cleanup_test.dart` |
| **Subtask Column** | Third column listing subtasks for the selected task. | `_buildSubtaskColumn` in `app.dart`. | `nav_create_cleanup_test.dart` |
| **Keyboard Navigation** | Arrow keys to navigate between columns and items. Enter to create new items. | `KeyboardListener` in `MyApp`. Custom `FocusNode` management. | `hierarchical_navigation_test.dart`, `enter_add_test.dart` |
| **Auto-Cleanup** | Empty items are automatically deleted when navigating away (unless they are the current selection). | `_cleanupEmptyItemsExcludingSelected` logic in `app.dart`. | `deletion_test.dart`, `nav_create_cleanup_test.dart` |
| **Focus Stability** | Preserves focus on input fields to prevent flickering during state updates. | `EditableItemWidget` uses local controllers and leaf-widget isolation. | `focus_repro_test.dart` |
| **Responsive Layout** | Switches between 3-column row (Desktop) and single-column stack (Mobile). | `LayoutBuilder` in `app.dart`. Desktop: `Row`. Mobile: `Scaffold` stack. | `widget_test.dart` (Must force screen size) |

## 2. AI Assistant Integration

An intelligent assistant integrated directly into the workflow, powered by Google's Gemini models via Firebase.

| Feature | Description | Implementation Details | Associated Tests |
| :--- | :--- | :--- | :--- |
| **Standard Mode** | Concise, execution-focused AI behavior. Immediately proposes tools. | `AssistantService` logic. | `assistant_logic_test.dart` |
| **Thinking Mode** | Mentor-like behavior. Analyzes requests deeper before acting. Controlled via UI toggle. | `AssistantService` logic with specific system prompts. | `mentor_mode_test.dart` |
| **Tool Execution** | AI can manipulate app state (Add/Delete/Update tasks). | `ToolRegistry` and `lib/ai_tools/implementations/`. | `assistant_logic_test.dart` |
| **Review Layer** | "Human-in-the-loop" workflow. AI proposes actions (Pending), User accepts/declines. | `ProposedAction` model. `_pendingActions` list in `AssistantService`. | `review_layer_test.dart`, `interaction_test.dart` |
| **Voice Interaction** | Speech-to-Text input and Text-to-Speech output. | `speech_to_text` and `flutter_tts` packages. | N/A (Manual testing mostly) |
| **Chat History** | Persists chat messages and actions. | `DataService` saves `ChatMessage`. | `assistant_logic_test.dart` |
| **Model Abstraction** | `AIWrapper` interface to swap/mock the underlying Generative Model. | `lib/services/ai_wrapper.dart`. | `review_layer_test.dart` (Uses `MockAIModelWrapper`) |

## 3. Knowledge & Memory

Features for long-term retention of user preferences and facts.

| Feature | Description | Implementation Details | Associated Tests |
| :--- | :--- | :--- | :--- |
| **Knowledge Base UI** | Screen to view, edit, and delete saved memories/facts. | `lib/ui/knowledge_screen.dart`. | `widget_test.dart` (Partial coverage) |
| **Save Memory Tool** | AI Tool (`save_memory`) allowing the assistant to persist facts to the DB. | `SaveMemoryTool` in `lib/ai_tools/implementations/`. | `assistant_logic_test.dart` |
| **Retrieval** | (Planned/Partial) Injecting relevant knowledge into context. | `DataService.getAllKnowledge()`. | N/A |

## 4. Data Persistence & Interop

| Feature | Description | Implementation Details | Associated Tests |
| :--- | :--- | :--- | :--- |
| **Isar Database** | High-performance local database for all models (Project, Task, Chat, Knowledge). | `IsarStorageRepository`. | `checked_persistence_test.dart` |
| **Markdown Backup** | Automatic backup of project data to a human-readable Markdown file. | `MarkdownPersistenceService`. | N/A |
| **MCP Server** | Model Context Protocol implementation to expose app data/tools to external agents (e.g., Cursor). | `lib/services/mcp_server.dart`. | `mcp_server_test.dart` |

## 5. Architectural Conventions

*   **State Management:** `flutter_riverpod` for Dependency Injection and State.
*   **Service Pattern:** Logic resides in `Service` classes (`AssistantService`, `DataService`), not Widgets.
*   **Repository Pattern:** `DataService` delegates to `StorageRepository` (abstracted for Isar vs Memory).
*   **Leaf-Widget Optimization:** Complex list items (`EditableItemWidget`) manage their own text controllers to avoid rebuilding the entire list on every keystroke.
*   **Desktop-First Testing:** Widget tests interacting with the column layout MUST set `tester.view.physicalSize` to a large landscape resolution (e.g., 2000x1000) to ensure widgets are visible/found.

## 6. Known Configuration

*   **Firebase AI Model:** Uses `gemini-3-flash-preview`.
*   **Region Config:** Must use `location: 'global'` in `FirebaseAI.vertexAI()` for the preview model to work.
*   **Target Platform:** macOS (primary), supports Web/Mobile layouts.

## 7. Test Suite Index

*   `assistant_logic_test.dart`: Unit tests for AI Tool parsing and chat flow.
*   `mentor_mode_test.dart`: Verifies Thinking Mode prompt injection and behavior.
*   `review_layer_test.dart`: Tests the Propose -> Accept/Decline workflow.
*   `nav_create_cleanup_test.dart`: Integration test for Column UI, creation, and auto-cleanup.
*   `focus_repro_test.dart`: Regression test for focus loss/flickering.
*   `hierarchical_navigation_test.dart`: Tests arrow key navigation logic.
*   `mcp_server_test.dart`: Verifies MCP endpoints (GET/POST projects/tasks).
*   `checked_persistence_test.dart`: Verifies data is correctly saved to Isar/Repositories.

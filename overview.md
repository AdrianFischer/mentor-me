# Project Overview

| **identifier**<br>Description | State | Focus |
|:---|:---|:---|
| **add_ai_footer**<br>Add 'Built with Assisted Intelligence' text to the app home screen. | Completed | Done |
| **implement_responsive_layout**<br>Implement layout-based responsive UI for mobile and desktop. | Completed | Implementation & Verification |
| **f6a85b37-42ae-470e-98bf-91e93b0ac0b8**<br>test adding a task in the new project | In Progress | Initial Scope |
| **a2e028aa-98ff-46eb-971a-186bf20cc0c5**<br>hahaha | In Progress | Initial Scope |
| **bb8b0f96-0fc5-434e-b252-e95a9435d892**<br>with my second tasks | In Progress | Initial Scope |
| **2b75436b-c12d-442d-8e28-b46503ce9e32**<br>Add a "Talk to Mentor" mode to this app | In Progress | Initial Scope |
| **bc0829d5-b1d8-4a7f-8735-8b062a5df574**<br>Make the To do app as useful as possible for ME | In Progress | Initial Scope |
| **610994aa-bb71-4c27-bc9f-7968aef8f20e**<br>Connect this to do list with your daily work flow | In Progress | Initial Scope |
| **72839924-1c3c-4569-af6c-46a0f8c7b708**<br>Create a MVP of ANY product and release it to the market | In Progress | Initial Scope |
| **27121644-1ec2-404b-8c54-884c9703e75a**<br>this is a big new task | In Progress | Initial Scope |
| **fix_project_persistence**<br>Fix project persistence in Flutter App | Completed | Verification |
| **implement_robust_persistence**<br>Implement robust data persistence with debouncing, atomic writes, and subtask support. | Completed | Done |
| **migrate_to_ai_kb**<br>Migrate Flutter app to AI-First Knowledge Base. | Completed | Done |
| **verify_add_project_tool**<br>Try out and test adding new projects in the Ai assistant | Completed | None |
| **debug_crash**<br>Debug crash when opening Assisted AI project | Completed | Monitoring |
| **verify_ai_project_flow**<br>Verify AI Project Flow via Structured Logging | Completed | Verified Successfully |
| **verify_checked_persistence**<br>Verify checked state persistence in design specs app | Completed | Verification |
| **verify_ai_create_project**<br>Verify 'adis project' creation via AI Assistant | Starting verification | AI Assistant Interaction |
| **agent_dx_improvements**<br>Improve Developer Experience (DX) and Testing Infrastructure for Autonomous Agents | Completed | Debug Overlay |
| **tests_deep_undo**<br>Create tests for Deep Undo Integration and Branch Off Strategy | Completed | Testing verification |
| **deep_undo_integration**<br>Implement Deep Undo Integration using Command Pattern. | Completed | Integration Verified |
| **verify_config_setup**<br>Verify environment configuration and API key loading. | Completed | Integration |
| **document_feature_list**<br>Document feature list from design specs 2025_12_13 | Completed | Documentation |
| **implement_backspace_deletion**<br>Implement backspace deletion for list items. | Completed | Maintenance |
| **implement_3_column_interaction**<br>Refined hierarchical navigation: strict boundary checks for column jumping. | Completed | Robustness & Tests |
| **web_dev_infra**<br>Set up web development infrastructure for the Flutter app. | Completed | Infrastructure |
| **verify_and_fix_features**<br>Verify all features in FEATURES.md, add tests for failures, and fix them. | Completed | Integration |
| **remove_empty_elements**<br>Automatically remove empty list elements unless they have children. | Completed | Testing verification |
| **auto_create_on_nav**<br>Auto-create new item on right arrow navigation if column is empty. | Completed | Testing verification |
| **auto_focus_new_item**<br>Auto-focus newly created list items to enable immediate typing. | Completed | Testing verification |
| **implement_enter_to_add**<br>Implement Enter key behavior to add new list element. | Completed | Testing verification |
| **change_enter_shortcut**<br>Change behavior to require Cmd+Enter to mark task as done. | Completed | Testing verification |
| **web_dev_infra_setup**<br>Enable web development workflow for the Flutter app | Completed | Ready for use |
| **improve_pipeline_robustness**<br>Improve Autonomous Pipeline Robustness | Completed | Maintenance |
| **create_flutter_app_pipeline**<br>Create Flutter App with Autonomous Pipeline | Completed | Maintenance |
| **design_ui_concepts**<br>Design 10 innovative UI/UX concepts for the keyboard-driven interface | Completed | Design Completed |
| **marco_strategic_discussion**<br>Prepare strategic discussion points for conversation with Marco (Chris's boss) | Preparing | Podcast rehearsal |
| **glt_release_preparation**<br>Prepare release for GLT | Optimization & Profiling | Snapshot implementation for caching |
| **implement_tagging_system**<br>Allow tagging of projects, tasks, and subtasks for cross-cutting views. | Completed | Done |
| **ai_agent_button**<br>Add AI Assistant button to header to switch to Chat mode. | Completed | Done |
| **mcp_integration_basic**<br>Basic MCP Server and Client integration for Agent-App communication. | Completed | Done |
| **display_artifacts_pretty**<br>Render Markdown artifacts nicely in the Assistant Screen. | Pending | Implementation |
| **multi_select_actions**<br>Allow multi-selection of tasks for bulk agent actions ("Start Work"). | Pending | Design & Implementation |

## System Capabilities

- **Data Persistence:**
    - **Isar Database:** Local, high-performance NoSQL database for structured data (Projects, Tasks, Chat).
    - **Markdown Sync:** Two-way synchronization with local Markdown files for portability.
- **MCP Server (HTTP API):**
    -   **Embedded Server:** Runs on port `8081` (default) within the Flutter app.
    -   **Endpoints:** 
        -   `GET /projects`: Retrieve full hierarchy.
        -   `POST /tasks`: Add new task (simplified payload supported).
        -   `POST /tasks/<taskId>/subtasks`: Add subtask to a specific task.
        -   `POST /items/<itemId>/status`: Update the completion status of any item (project, task, or subtask).
    -   **Discovery:** Exposes capabilities via `/mcp/tools`.
- **State Management:** Riverpod for reactive, testable state.
- **Selection & Navigation Architecture:**
    -   **SelectionProvider (Riverpod):** Centralized state management for all selection logic (projects, tasks, conversations, tags). Encapsulates navigation rules and auto-cleanup of empty items.
    -   **Shortcuts & Actions:** Uses Flutter's native Intent/Action system to handle keyboard navigation globally, decoupling input events from specific widget focus.
- **AI Integration:** Google Gemini API for generating task structures and chat responses.

Last updated: 2025-12-30
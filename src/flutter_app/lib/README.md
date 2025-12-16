# AI-First App Architecture

This application is designed with an "AI-First" philosophy, meaning the core logic is exposed as executable tools that both the UI and AI agents can use.

## Architecture Layers

1.  **UI Layer (`ui/`)**: "Dumb" widgets that render state and dispatch actions via Providers.
2.  **Providers (`providers/`)**: State management using Riverpod. Connects UI to Services.
3.  **Services (`services/`)**: The business logic and "Source of Truth". Contains methods like `addProject`, `addTask`.
4.  **AI Tools (`ai_tools/`)**: The interface for AI agents (Gemini/Vertex). Maps natural language intents to Service methods.
5.  **Data (`data/`)**: Persistence and Data Models.

## Key Principles
-   **Headless State**: The app state exists independently of the UI.
-   **Tool-Based Interaction**: Every feature is a "tool" (e.g., `add_task`).
-   **UUIDs**: All entities use UUIDs to ensure stable references for the AI.





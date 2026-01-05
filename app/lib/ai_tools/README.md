# AI Tools Interface

This directory contains the bridge between the AI Agent (Gemini/Vertex AI) and the App's Logic.

## Files
-   **`tool_definitions.dart`**: JSON Schemas defining the tools available to the AI. These are sent to the LLM.
-   **`tool_registry.dart`**: The execution logic. Maps the tool name (string) from the LLM to the actual Dart function in `DataService`.

## How to Add a New Tool
1.  Define the function in `DataService` (e.g., `archiveProject(id)`).
2.  Add the JSON Schema in `ToolDefinitions`.
3.  Add the case in `ToolRegistry` to call the service.





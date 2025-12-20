# Plan: Integration of MCP Server (HTTP API)

## Objective
Make the local storage (Isar DB) of the Flutter application available to external tools (like the CLI agent) while the application is running.

## Proposed Solution
Implement a lightweight HTTP server ("MCP Server") embedded within the Flutter application. This server exposes REST endpoints to query and modify the application state.

### Rationale
- **Concurrency:** Accessing the embedded Isar database from a separate process is risky or impossible (locking). Embedding the server in the app ensures safe access via the existing Repository layer.
- **Simplicity:** HTTP/JSON is universally accessible.
- **Extensibility:** Can be expanded to full MCP (Model Context Protocol) compliance (JSON-RPC) easily.

## Implementation Steps (Executed)

1.  **Dependencies:**
    -   Added `shelf` and `shelf_router` to `pubspec.yaml`.

2.  **Service Implementation (`lib/services/mcp_server.dart`):**
    -   Created `McpServerService`.
    -   Endpoints:
        -   `GET /projects`: List all projects and tasks.
        -   `POST /projects`: Create/Update project.
        -   `GET /tasks`: List all tasks (flat).
        -   `POST /tasks`: Create/Update task.
        -   `DELETE /tasks/<id>`: Delete task.
        -   `GET /knowledge`: List knowledge items.
        -   `GET /mcp/tools`: Discovery endpoint for capabilities.
    -   Port: `8081` (default).

3.  **Integration:**
    -   Created `lib/providers/mcp_provider.dart` to manage the service lifecycle.
    -   Modified `lib/app.dart` to initialize the server on app startup.

4.  **Verification:**
    -   Created `test/mcp_server_test.dart`.
    -   Verified endpoints using mocked `StorageRepository`.

## Usage
1.  Run the Flutter app (`flutter run -d macos`).
2.  From CLI:
    -   `curl http://localhost:8081/projects`
    -   `curl http://localhost:8081/mcp/tools`

## Future Work
-   Implement full MCP JSON-RPC 2.0 protocol if needed.
-   Add security (local auth token) if exposed beyond localhost.

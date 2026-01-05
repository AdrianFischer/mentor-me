# MCP Server Setup for Gemini CLI

This Flutter application contains an embedded **Model Context Protocol (MCP) Server**. This allows the Gemini CLI (and other MCP clients) to interact with the app's data (Projects, Tasks, Knowledge Base) directly.

## 1. Start the App

The MCP Server starts automatically when the Flutter app is running.

Run the app for macOS:
```bash
flutter run -d macos
```

The server listens on **port 8081** (or increments if busy) and exposes an endpoint at `/mcp`.

## 2. Configure Gemini CLI

To connect the Gemini CLI to this app, add the following configuration to your Gemini CLI's `settings.json`.

**Location of `settings.json`:**
*   **macOS/Linux:** `~/.geminiclirc` or `~/.config/gemini/settings.json` (Check `gemini config --list` to find the exact path or use `gemini config edit`)

**Configuration to Add:**

```json
{
  "mcpServers": {
    "flutterApp": {
      "url": "http://localhost:8081/mcp"
    }
  }
}
```

## 3. Configure Cursor (or other Stdio Clients)

Cursor requires a command-line interface (Stdio) for MCP servers. Use the included bridge script to adapt the HTTP/SSE server for Cursor.

**Configuration:**
In your project `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "flutterApp": {
      "type": "stdio",
      "command": "dart",
      "args": ["run", "app/bin/mcp_bridge.dart", "http://localhost:8081/mcp"]
    }
  }
}
```
*Note: Ensure the path to `app/bin/mcp_bridge.dart` is correct relative to your workspace root, or use an absolute path.*

## 4. Verify Connection

Once the app is running and the config is saved:

1.  Restart the Gemini CLI or Cursor.
2.  **Gemini CLI:** Run `gemini mcp list`. You should see `flutterApp` listed with a status of `Connected`.
3.  **Cursor:** Check the "MCP Servers" section in Cursor settings or try asking the Agent "What projects do I have?".

## Available Tools

The app exposes the following tools to Gemini:
*   `get_projects`: List all projects and tasks.
*   `add_project`: Create a new project.
*   `add_task`: Add a task to a project.
*   `add_subtask`: Add a subtask.
*   `update_item_status`: Complete/Uncomplete items.
*   `delete_item`: Delete projects, tasks, or subtasks.
*   `get_knowledge`: Retrieve knowledge base entries.
*   And more... (Check code for full list)

## Troubleshooting

*   **Port Conflict:** If port 8081 is in use, the app tries 8082, 8083, etc. Check the Flutter app's console logs for: `MCP Server listening on http://localhost:xxxx/mcp` and update your `settings.json` accordingly.
*   **Connection Refused:** Ensure the Flutter app is actually running.
*   **Cursor Connection:** If Cursor fails to connect, ensure `dart` is in your PATH and the bridge script path is correct. You can test the bridge manually: `dart run app/bin/mcp_bridge.dart` and paste a JSON-RPC message.
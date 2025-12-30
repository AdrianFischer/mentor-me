# MCP Connection Bug Report

**Date:** 2025-01-30  
**Issue:** Cursor cannot connect to Flutter App MCP Server via bridge  
**Status:** Connection shows "Not connected" error

## Symptoms

- MCP tools return `{"error":"Not connected"}` when called from Cursor
- Flutter app is running and MCP server is accessible via HTTP
- Bridge configuration appears correct
- Direct HTTP connection to MCP server works (returns SSE events)

## Environment

- **OS:** macOS (darwin 25.1.0)
- **Cursor:** Reloaded window after Flutter app restart
- **Flutter App:** Running (PID 26128) on port 8081
- **Dart:** Available at `/opt/homebrew/bin/dart`

## Configuration

### Cursor MCP Config (`~/.cursor/mcp.json`)
```json
{
  "mcpServers": {
    "dart": {
      "type": "stdio",
      "command": "dart mcp-server --experimental-mcp-server --force-roots-fallback",
      "env": {},
      "args": []
    },
    "flutterApp": {
      "command": "dart",
      "args": ["run", "/Users/adi/dev/AssistedIntelligence/src/flutter_app/bin/mcp_bridge.dart", "http://localhost:8081/mcp"]
    }
  }
}
```

### Flutter App MCP Server
- **Port:** 8081 (or increments if busy)
- **Endpoint:** `http://localhost:8081/mcp`
- **Protocol:** HTTP/SSE (Server-Sent Events)
- **Transport:** Custom SSE transport implementation

## Diagnostic Information

### 1. Flutter App Status
```bash
$ lsof -i :8081 | grep flutter
flutter_a 26128  adi   15u  IPv4  TCP *:sunproxyadmin (LISTEN)
flutter_a 26128  adi   23u  IPv4  TCP localhost:sunproxyadmin->localhost:54159 (ESTABLISHED)
flutter_a 26128  adi   24u  IPv4  TCP localhost:sunproxyadmin->localhost:54160 (ESTABLISHED)
```
✅ **Flutter app is running and listening on port 8081**

### 2. MCP Server HTTP Endpoint Test
```bash
$ curl -s -m 2 http://localhost:8081/mcp
event: endpoint
data: /mcp?sessionId=9dd74a90-99b7-4a58-a3bb-e516135ff462
```
✅ **MCP server responds with SSE endpoint event**

### 3. Bridge Script Location
- **Path:** `/Users/adi/dev/AssistedIntelligence/src/flutter_app/bin/mcp_bridge.dart`
- **Status:** File exists and is readable
- **Dependencies:** Uses `dart:io` for HTTP client and stdio

### 4. Bridge Process Status
- ✅ **Bridge process IS running** (PID 26967): `/opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart run /Users/adi/dev/AssistedIntelligence/src/flutter_app/bin/mcp_bridge.dart http://localhost:8081/mcp`
- Bridge process started by Cursor and is active
- However, MCP tools are still not available in Cursor
- This suggests the bridge is running but not successfully completing the MCP protocol handshake with Cursor

## Potential Issues

### Issue 1: Bridge Process Running But Tools Not Available ✅ CONFIRMED
**Status:** Bridge process IS running (PID 26967), but Cursor doesn't see the MCP tools.

**Evidence:**
- ✅ Bridge process is running: `ps aux | grep mcp_bridge` shows active process
- ❌ MCP tools not available in Cursor (returns "Tool not found" error)
- ✅ Flutter app MCP server is responding to HTTP requests
- ✅ Config includes `"type": "stdio"` (added as fix)

**Possible Causes:**
1. **MCP Protocol Handshake Issue:** Bridge may not be properly forwarding the `initialize` handshake
2. **Message Format Issue:** Bridge might not be correctly formatting JSON-RPC messages
3. **Response Handling:** Bridge might not be properly forwarding responses from server to Cursor
4. **Tool Discovery:** Cursor might not be receiving the `tools/list` response correctly

### Issue 2: Session ID Handling
**Hypothesis:** The bridge may not be correctly handling the session ID from the SSE endpoint event.

**Evidence from Code:**
- MCP server POST endpoint expects `sessionId` as query parameter: `request.url.queryParameters['sessionId']`
- Bridge receives endpoint as: `/mcp?sessionId=...` in SSE event
- Bridge resolves endpoint: `Uri.parse(baseUrl).resolve(postEndpoint!)`

**Potential Problem:**
If `baseUrl` is `http://localhost:8081/mcp` and `postEndpoint` is `/mcp?sessionId=...`, the resolved URL might be incorrect.

### Issue 3: Missing Configuration
**Hypothesis:** The flutterApp server config might be missing required fields.

**Current Config:**
```json
"flutterApp": {
  "command": "dart",
  "args": ["run", "/Users/adi/dev/AssistedIntelligence/src/flutter_app/bin/mcp_bridge.dart", "http://localhost:8081/mcp"]
}
```

**Comparison with working "dart" server:**
```json
"dart": {
  "type": "stdio",  // <-- This is present
  "command": "dart mcp-server --experimental-mcp-server --force-roots-fallback",
  "env": {},
  "args": []
}
```

**Missing:** `"type": "stdio"` field for flutterApp

## Recommended Fixes

### Fix 1: Add explicit stdio type
```json
"flutterApp": {
  "type": "stdio",
  "command": "dart",
  "args": ["run", "/Users/adi/dev/AssistedIntelligence/src/flutter_app/bin/mcp_bridge.dart", "http://localhost:8081/mcp"]
}
```

### Fix 2: Test bridge manually
```bash
cd /Users/adi/dev/AssistedIntelligence
dart run src/flutter_app/bin/mcp_bridge.dart http://localhost:8081/mcp
```
Then manually send JSON-RPC messages via stdin to verify bridge works.

### Fix 3: Check Cursor logs
- Look for MCP server connection errors in Cursor's developer console
- Check if bridge process is being spawned
- Verify any error messages from bridge stderr

### Fix 4: Verify bridge endpoint resolution
In `mcp_bridge.dart`, ensure the POST endpoint URL is correctly constructed:
```dart
// Current: Uri.parse(baseUrl).resolve(postEndpoint!)
// postEndpoint might be: "/mcp?sessionId=xxx"
// baseUrl is: "http://localhost:8081/mcp"
// Result might be: "http://localhost:8081/mcp/mcp?sessionId=xxx" (WRONG)
// Should be: "http://localhost:8081/mcp?sessionId=xxx"
```

## Test Cases

1. ✅ Flutter app starts and MCP server listens on port 8081
2. ✅ HTTP GET to `/mcp` returns SSE endpoint event
3. ❌ Cursor MCP tools return "Not connected"
4. ❓ Bridge process should be running (not verified)
5. ❓ Manual bridge test (not completed - timeout command not available on macOS)

## Next Steps

1. Add `"type": "stdio"` to flutterApp config
2. Test bridge manually with a simple JSON-RPC message
3. Check Cursor's MCP connection logs
4. Verify bridge endpoint URL resolution logic
5. Consider adding more verbose logging to bridge script

## Related Files

- MCP Server: `src/flutter_app/lib/services/mcp_server.dart`
- Bridge Script: `src/flutter_app/bin/mcp_bridge.dart`
- Cursor Config: `~/.cursor/mcp.json`
- Setup Docs: `src/flutter_app/MCP_SETUP.md`



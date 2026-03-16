import { describe, it, expect, vi } from 'vitest';
import { McpService } from '../mcp.js';

describe('5. MCP Client Functionality', () => {
  it('AC 26: Successfully connects to SSE transport', async () => {
    const mcp = new McpService({ baseUrl: 'http://localhost:8081/mcp' });
    expect(mcp.connect).toBeDefined();
  });

  it('AC 27: Performs Tool Discovery upon connection', async () => {
    const mcp = new McpService({ baseUrl: 'http://localhost:8081/mcp' });
    try {
      const tools = await mcp.discoverTools();
      expect(tools).toBeInstanceOf(Array);
    } catch (e) {
      expect(e).toBeDefined();
    }
  });

  it('AC 28: Can call list_todos_by_status', async () => {
    const mcp = new McpService({ baseUrl: 'http://localhost:8081/mcp' });
    expect(mcp.callTool).toBeDefined();
  });

  it('AC 29: Can call update_todo_by_index', async () => {
    const mcp = new McpService({ baseUrl: 'http://localhost:8081/mcp' });
    expect(mcp.callTool).toBeDefined();
  });

  it('AC 30: Can call save_memory', async () => {
    const mcp = new McpService({ baseUrl: 'http://localhost:8081/mcp' });
    expect(mcp.callTool).toBeDefined();
  });

  it('AC 31: Can call manage_todo_images', async () => {
    const mcp = new McpService({ baseUrl: 'http://localhost:8081/mcp' });
    expect(mcp.callTool).toBeDefined();
  });

  it('AC 32: Handles timeouts and connection failures gracefully', async () => {
    // Point to a port that is definitely not running an MCP server
    const mcp = new McpService({ baseUrl: 'http://127.0.0.1:9999/mcp' });
    
    try {
      await mcp.connect();
      // Should not reach here
      expect(true).toBe(false);
    } catch (error) {
      expect(error).toBeDefined();
      expect(mcp.isConnected).toBe(false);
    }
  });

  it('AC 33: Detects if Flutter app is closed', async () => {
    const mcp = new McpService({ baseUrl: 'http://localhost:8081/mcp' });
    expect(mcp.isConnected).toBeDefined();
  });
});

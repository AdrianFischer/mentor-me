import { describe, it, expect, vi } from 'vitest';
import { AgentBrain } from '../agent.js';
import { McpService } from '../mcp.js';
import { GeminiService } from '../gemini.js';

describe('AgentBrain Error Handling', () => {
  it('reproduces the Telegram error when MCP is offline, now gracefully handled', async () => {
    const config = {
      telegramToken: 'fake',
      geminiApiKey: 'fake',
      authorizedUserIds: [123],
      baseUrl: 'http://127.0.0.1:9999/mcp', // Guaranteed to be offline
      logsDir: './logs',
      dataDir: './data'
    };

    const mcp = new McpService(config);
    const gemini = new GeminiService(config.geminiApiKey);
    
    // Mock gemini to succeed
    vi.spyOn(gemini, 'process').mockResolvedValue({
      text: 'I am a graceful conversational response without MCP tools.',
      toolCalls: []
    });

    const brain = new AgentBrain({ mcp, gemini });

    const response = await brain.process('hallo', () => {});
    
    // It should no longer throw ECONNREFUSED but return the conversational string
    expect(response).not.toMatch(/❌ Sorry/);
    expect(response).not.toMatch(/ECONNREFUSED/);
    expect(response).toBe('I am a graceful conversational response without MCP tools.');
  });
});

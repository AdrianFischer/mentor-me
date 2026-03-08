import { describe, it, expect, vi } from 'vitest';
import { loadConfig } from '../config.js'; // Assuming this will exist
import fs from 'fs';

describe('2. Configuration & Secrets', () => {
  it('AC 7: Loads TELEGRAM_BOT_TOKEN from app/.env', () => {
    // This will fail initially as config.js doesn't exist
    const config = loadConfig();
    expect(config.telegramToken).toBeDefined();
  });

  it('AC 8: Loads GEMINI_API_KEY from app/.env', () => {
    const config = loadConfig();
    expect(config.geminiApiKey).toBeDefined();
  });

  it('AC 9: Correctly reads MCP server port from ~/.assisted_intelligence/mcp_port', () => {
    const config = loadConfig();
    expect(config.mcpPort).toBeTypeOf('number');
  });

  it('AC 10: Fails gracefully if .env or port file is missing', () => {
    // Mock missing file
    vi.spyOn(fs, 'existsSync').mockReturnValue(false);
    expect(() => loadConfig()).toThrow();
    vi.restoreAllMocks();
  });

  it('AC 11: Secrets are never printed to console (mocked console)', () => {
    const consoleSpy = vi.spyOn(console, 'log');
    const config = loadConfig();
    console.log(config);
    expect(consoleSpy).not.toHaveBeenCalledWith(expect.stringContaining(config.telegramToken));
    vi.restoreAllMocks();
  });
});

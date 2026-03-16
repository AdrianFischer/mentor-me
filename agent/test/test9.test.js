import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { loadConfig } from '../config.js';
import fs from 'fs';
import path from 'path';

describe('Test 9: MCP Auto-Discovery Read Resilience Test', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    vi.resetModules();
    process.env = { ...originalEnv };
    process.env.TELEGRAM_BOT_TOKEN = 'mock_token';
    process.env.GEMINI_API_KEY = 'mock_key';
    process.env.HOME = '/mock/home';
    
    // Default mock for existsSync (so .env check passes)
    vi.spyOn(fs, 'existsSync').mockImplementation((p) => {
      if (typeof p === 'string' && p.endsWith('.env')) return true;
      return false; // Default to not existing
    });
  });

  afterEach(() => {
    process.env = originalEnv;
    vi.restoreAllMocks();
  });

  it('AC 9.1: Handles missing mcp_port file gracefully by falling back to default port', () => {
    // fs.existsSync returns true for .env, false for others
    const config = loadConfig();
    expect(config.mcpPort).toBe(8081); // Default port
  });

  it('AC 9.2: Handles corrupted mcp_port file (cannot read file) without crashing', () => {
    const portFilePath = path.join('/mock/home', '.assisted_intelligence', 'mcp_port');
    
    vi.spyOn(fs, 'existsSync').mockImplementation((p) => {
      if (typeof p === 'string' && p.endsWith('.env')) return true;
      if (p === portFilePath) return true;
      return false;
    });

    vi.spyOn(fs, 'readFileSync').mockImplementation((p) => {
      if (p === portFilePath) throw new Error('EACCES: permission denied');
      return '';
    });

    expect(() => loadConfig()).not.toThrow();
    const config = loadConfig();
    expect(config.mcpPort).toBe(8081);
  });

  it('AC 9.3: Handles invalid non-numeric port in mcp_port gracefully', () => {
    const portFilePath = path.join('/mock/home', '.assisted_intelligence', 'mcp_port');
    
    vi.spyOn(fs, 'existsSync').mockImplementation((p) => {
      if (typeof p === 'string' && p.endsWith('.env')) return true;
      if (p === portFilePath) return true;
      return false;
    });

    vi.spyOn(fs, 'readFileSync').mockImplementation((p) => {
      if (p === portFilePath) return 'invalid_port\n';
      return '';
    });

    expect(() => loadConfig()).not.toThrow();
    const config = loadConfig();
    expect(config.mcpPort).toBe(8081);
  });
});

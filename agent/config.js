import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import os from 'path';

/**
 * Loads configuration from .env and system files.
 * @throws {Error} if critical config is missing.
 */
export function loadConfig() {
  const envPath = path.resolve('../app/.env');
  if (!fs.existsSync(envPath)) {
    throw new Error(`Environment file missing at ${envPath}`);
  }

  dotenv.config({ path: envPath, override: true });

  const telegramToken = process.env.TELEGRAM_BOT_TOKEN;
  const geminiApiKey = process.env.GEMINI_API_KEY;

  if (!telegramToken || !geminiApiKey) {
    throw new Error('Critical secrets (TELEGRAM_BOT_TOKEN or GEMINI_API_KEY) missing in .env');
  }

  // MCP Port Discovery
  let mcpPort = 8081;
  const homeDir = process.env.HOME || process.env.USERPROFILE;
  const portFilePath = path.join(homeDir, '.assisted_intelligence', 'mcp_port');

  if (fs.existsSync(portFilePath)) {
    const portData = fs.readFileSync(portFilePath, 'utf-8').trim();
    mcpPort = parseInt(portData, 10);
  }

  return {
    telegramToken,
    geminiApiKey,
    mcpPort,
    baseUrl: `http://127.0.0.1:${mcpPort}/mcp`
  };
}

import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/**
 * Loads configuration from .env and system files.
 * @throws {Error} if critical config is missing.
 */
export function loadConfig() {
  const envPath = process.env.ENV_PATH || path.resolve(__dirname, '../app/.env');
  if (!fs.existsSync(envPath)) {
    throw new Error(`Environment file missing at ${envPath}`);
  }

  dotenv.config({ path: envPath, override: true });

  const telegramToken = process.env.TELEGRAM_BOT_TOKEN;
  const geminiApiKey = process.env.GEMINI_API_KEY;
  const authorizedUserIdsRaw = process.env.AUTHORIZED_USER_IDS || '';
  const authorizedUserIds = authorizedUserIdsRaw.split(',').map(id => parseInt(id.trim(), 10)).filter(id => !isNaN(id));

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

  // Configurable paths (for Docker volume mounts)
  const dataDir = process.env.DATA_DIR || path.resolve(__dirname, '../data');
  const logsDir = process.env.LOGS_DIR || path.resolve(__dirname, '../logs');
  const mcpHost = process.env.MCP_HOST || '127.0.0.1';

  return {
    telegramToken,
    geminiApiKey,
    authorizedUserIds,
    mcpPort,
    mcpHost,
    baseUrl: `http://${mcpHost}:${mcpPort}/mcp`,
    dataDir,
    logsDir,
  };
}

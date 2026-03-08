import { loadConfig } from './config.js';
import { McpService } from './mcp.js';
import { GeminiService } from './gemini.js';
import { BotService } from './telegram.js';
import { AgentBrain } from './agent.js';
import { logger } from './logger.js';

async function main() {
  logger.info('🚀 Starting Assisted Intelligence Agent...');
  
  // Initial wait to ensure Flutter app starts its server
  await new Promise(resolve => setTimeout(resolve, 5000));

  try {
    // 1. Load Configuration
    const config = loadConfig();

    // 2. Initialize Services
    const mcp = new McpService(config);
    const gemini = new GeminiService(config);
    
    // Connect to MCP (Flutter App) with retries
    let connected = false;
    let retries = 10;
    while (!connected && retries > 0) {
      try {
        await mcp.connect();
        connected = true;
        logger.info('✅ MCP Connected');
      } catch (e) {
        retries--;
        if (retries === 0) throw e;
        logger.warn(`Waiting for MCP server (Retries left: ${retries})...`);
        await new Promise(resolve => setTimeout(resolve, 3000)); // Wait 3s
      }
    }

    // 3. Initialize Brain
    const brain = new AgentBrain({ mcp, gemini });

    // 4. Start Telegram Bot
    const bot = new BotService(config, brain);
    await bot.start();

    logger.info('✨ Agent is now live and talking to your bot');

    // Handle Shutdown
    process.once('SIGINT', () => {
      logger.info('Shutting down...');
      bot.stop('SIGINT');
    });
    process.once('SIGTERM', () => {
      logger.info('Shutting down...');
      bot.stop('SIGTERM');
    });

  } catch (error) {
    logger.error('💥 Failed to start agent', error);
    process.exit(1);
  }
}

main();

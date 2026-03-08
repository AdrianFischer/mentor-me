import { loadConfig } from './config.js';
import { McpService } from './mcp.js';
import { GeminiService } from './gemini.js';
import { BotService } from './telegram.js';
import { AgentBrain } from './agent.js';
import { Watchdog } from './watchdog.js';
import { logger } from './logger.js';

async function main() {
  logger.info('🚀 Starting Assisted Intelligence Agent...');
  
  // Initial wait to ensure Flutter app starts its server
  await new Promise(resolve => setTimeout(resolve, 5000));

  try {
    // 1. Load Configuration
    // We wait 5s earlier, now we load config AFTER the wait so we get the fresh mcp_port file
    const config = loadConfig();
    logger.info(`Loaded ${config.authorizedUserIds.length} authorized Telegram users.`);

    // 2. Initialize Services
    const mcp = new McpService(config);
    const gemini = new GeminiService(config);
    
    // Connect to MCP (Flutter App) with retries
    let connected = false;
    let retries = 10;
    while (!connected && retries > 0) {
      try {
        // Reload config on retry to catch port changes
        const freshConfig = loadConfig();
        mcp.baseUrl = freshConfig.baseUrl;

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

    // 5. Start Autonomous Watchdog
    const primaryUserId = config.authorizedUserIds?.[0];
    const watchdog = new Watchdog({
      onWorkAccomplished: (message) => {
        if (primaryUserId) {
          bot.sendMessage(primaryUserId, message);
        } else {
          logger.warn('No authorized user found to send routine report.');
        }
      }
    });
    watchdog.start();

    logger.info('✨ Agent is now live and talking to your bot');

    // Handle Shutdown
    process.once('SIGINT', () => {
      logger.info('Shutting down...');
      watchdog.stop();
      bot.stop('SIGINT');
    });
    process.once('SIGTERM', () => {
      logger.info('Shutting down...');
      watchdog.stop();
      bot.stop('SIGTERM');
    });

  } catch (error) {
    logger.error('💥 Failed to start agent', error);
    process.exit(1);
  }
}

main();

import { loadConfig } from './config.js';
import { McpService } from './mcp.js';
import { GeminiService } from './gemini.js';
import { BotService } from './telegram.js';
import { AgentBrain } from './agent.js';
import { Watchdog } from './watchdog.js';
import { logger } from './logger.js';
import { DashboardService } from './dashboard.js';
import { ConductorManager } from './conductor_client.js';
import { createBrainWorker } from './workers/brain_worker.js';

async function main() {
  logger.info('🚀 Starting Assisted Intelligence Agent...');
  
  // Initial wait to ensure Flutter app starts its server
  await new Promise(resolve => setTimeout(resolve, 5000));

  try {
    // 1. Load Configuration
    const config = loadConfig();
    logger.info(`Loaded ${config.authorizedUserIds.length} authorized Telegram users.`);

    // 2. Initialize Core Services
    const mcp = new McpService(config);
    const gemini = new GeminiService(config);
    
    // 3. Initialize Brain
    const brain = new AgentBrain({ mcp, gemini });

    // 4. Initialize Conductor
    const conductor = new ConductorManager();
    const brainWorker = createBrainWorker(brain);
    conductor.startWorkers([brainWorker]);

    // 5. Start Telegram Bot
    const bot = new BotService(config, brain);
    await bot.start();

    // 6. Start System Dashboard Service (Available even if MCP is down)
    const dashboard = new DashboardService(8082, gemini);
    await dashboard.start();

    // 7. Connect to MCP (Flutter App) with retries
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
        if (retries === 0) {
          logger.error('❌ Failed to connect to MCP after 10 retries. Continuing without UI task integration.');
        } else {
          logger.warn(`Waiting for MCP server (Retries left: ${retries})...`);
          await new Promise(resolve => setTimeout(resolve, 3000)); // Wait 3s
        }
      }
    }
// 8. Start Autonomous Watchdog
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
brain.routinesManager.setWatchdog(watchdog);
dashboard.setWatchdog(watchdog);

logger.info('✨ Agent is now live and talking to your bot');

    // Handle Shutdown
    process.once('SIGINT', () => {
      logger.info('Shutting down...');
      watchdog.stop();
      bot.stop('SIGINT');
      dashboard.stop();
      conductor.stopWorkers();
    });
    process.once('SIGTERM', () => {
      logger.info('Shutting down...');
      watchdog.stop();
      bot.stop('SIGTERM');
      dashboard.stop();
      conductor.stopWorkers();
    });

  } catch (error) {
    logger.error('💥 Failed to start agent', error);
    process.exit(1);
  }
}

main();

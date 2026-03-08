import { Telegraf, Markup } from 'telegraf';
import { logger } from './logger.js';

export class BotService {
  constructor(config, brain) {
    this.token = config.telegramToken;
    this.brain = brain;
    this.telegraf = new Telegraf(this.token, {
      handlerTimeout: 300000 // 5 minutes for heavy thinking
    });
    this.setupHandlers();
  }

  setupHandlers() {
    this.telegraf.start((ctx) => this.handleStart(ctx));
    this.telegraf.help((ctx) => this.handleHelp(ctx));
    
    // Model Selection Command
    this.telegraf.command('model', (ctx) => this.handleModelCommand(ctx));
    
    // Workflow Commands
    this.telegraf.command('start_day', (ctx) => this.handleWorkflow(ctx, 'start-day'));
    this.telegraf.command('end_day', (ctx) => this.handleWorkflow(ctx, 'end-day'));
    
    // Actions for model selection
    this.telegraf.action('set_model_fast', (ctx) => this.handleSetModel(ctx, 'fast'));
    this.telegraf.action('set_model_smart', (ctx) => this.handleSetModel(ctx, 'smart'));

    this.telegraf.on('photo', async (ctx) => {
      try {
        await this.handlePhoto(ctx);
      } catch (error) {
        logger.error('Unhandled photo error', error);
        await ctx.reply('❌ An unexpected error occurred while processing your photo.');
      }
    });

    this.telegraf.on('message', async (ctx) => {
      try {
        await this.handleMessage(ctx);
      } catch (error) {
        logger.error('Unhandled message error', error);
        await ctx.reply('❌ An unexpected error occurred. Please try again.');
      }
    });
  }

  async handleStart(ctx) {
    await this.safeReply(ctx, '👋 Welcome to Assisted Intelligence! I am your AI agent. I can help you manage tasks and remember important facts.\n\nTry saying "Show my tasks" or "Remember I have a flight at 10 AM".');
  }

  async handleHelp(ctx) {
    await this.safeReply(ctx, '📖 *Assisted Intelligence Help*\n\nUsage examples:\n• "Show my tasks"\n• "Mark task 1 as completed"\n• "Remember that I like blue"\n• /model - Switch between fast and smart AI models\n• /start_day - Analyze today\'s priorities\n• /end_day - Summarize wins and plan tomorrow');
  }

  async handleWorkflow(ctx, type) {
    try {
      logger.info(`Starting Workflow: ${type}`);
      await ctx.sendChatAction('typing');
      
      const prompt = type === 'start-day' 
        ? "System: User is starting their day. Please analyze their current tasks and suggest the top 3 priorities for today based on their long-term goals and boss's expectations."
        : "System: User is ending their day. Please summarize their wins, check for any overdue tasks, and suggest a rough plan for tomorrow.";
      
      const response = await this.brain.handleUserMessage(prompt);
      await this.safeReply(ctx, response);
    } catch (error) {
      logger.error('Workflow Error', error);
      await ctx.reply(`❌ Sorry, I encountered an error during your ${type} workflow.`);
    }
  }

  async handleModelCommand(ctx) {
    await ctx.reply('🤖 *Select AI Model*\n\n• *Fast*: Gemini 2.0 Flash (Quick responses)\n• *Smart*: Gemini 3.1 Pro (Better reasoning)', {
      parse_mode: 'Markdown',
      ...Markup.inlineKeyboard([
        [Markup.button.callback('⚡ Fast', 'set_model_fast'), Markup.button.callback('🧠 Smart', 'set_model_smart')]
      ])
    });
  }

  async handleSetModel(ctx, type) {
    const success = this.brain.setModel(type);
    if (success) {
      logger.info(`Model switched to ${type}`);
      await ctx.answerCbQuery(`Switched to ${type} model`);
      await ctx.editMessageText(`✅ AI Model switched to *${type.toUpperCase()}*`, { parse_mode: 'Markdown' });
    } else {
      await ctx.answerCbQuery('Failed to switch model');
    }
  }

  async handleMessage(ctx) {
    if (ctx.message.voice) {
      return this.handleVoice(ctx);
    }
    
    const text = ctx.message.text;
    if (!text) return;

    try {
      logger.info(`Incoming from Telegram: "${text}"`);
      
      const response = await this.withTyping(ctx, () => 
        this.brain.process(text, (status) => {
          logger.info(`Status update: ${status}`);
        })
      );
      
      await this.safeReply(ctx, response);
    } catch (error) {
      logger.error('Telegram Error', error);
      await ctx.reply('❌ Sorry, something went wrong while thinking.');
    }
  }

  /**
   * Helper to keep the "typing" status alive during long processes.
   */
  async withTyping(ctx, fn) {
    // Send initial typing action
    ctx.sendChatAction('typing').catch(() => {});
    
    // Set up heartbeat (typing status lasts ~5s in Telegram)
    const interval = setInterval(() => {
      ctx.sendChatAction('typing').catch(() => {});
    }, 4000);

    try {
      return await fn();
    } finally {
      clearInterval(interval);
    }
  }

  /**
   * Safely replies with HTML or Photo, falling back to plain text if parsing fails.
   */
  async safeReply(ctx, response) {
    const text = typeof response === 'string' ? response : response.text;
    const imageBase64 = response.imageBase64;

    try {
      if (imageBase64) {
        const buffer = Buffer.from(imageBase64, 'base64');
        await ctx.replyWithPhoto({ source: buffer }, { 
          caption: text,
          parse_mode: 'HTML' 
        });
      } else {
        // Try with HTML (most reliable for bots)
        await ctx.reply(text, { parse_mode: 'HTML' });
      }
    } catch (error) {
      logger.warn('Rich reply failed, sending as plain text.', error.message);
      await ctx.reply(text); // Final fallback to plain text
    }
  }

  async handlePhoto(ctx) {
    try {
      const photos = ctx.message.photo;
      if (!photos || photos.length === 0) return;
      
      // Highest resolution is the last one in the array
      const photo = photos[photos.length - 1];
      logger.info(`Received photo: ${photo.file_id} (${photo.width}x${photo.height})`);
      
      // 1. Get file link from Telegram
      const link = await ctx.telegram.getFileLink(photo.file_id);
      
      // 2. Download the file
      const response = await fetch(link.href);
      if (!response.ok) throw new Error(`Failed to download photo: ${response.statusText}`);
      
      const buffer = await response.arrayBuffer();
      const imageBase64 = Buffer.from(buffer).toString('base64');
      
      // 3. Process with Brain
      const aiResponse = await this.withTyping(ctx, () => 
        this.brain.process({ 
          imageBase64, 
          mimeType: 'image/jpeg',
          text: ctx.message.caption 
        }, (status) => {
          logger.info(`Status update: ${status}`);
        })
      );
      
      await this.safeReply(ctx, aiResponse);
    } catch (error) {
      logger.error('Photo Processing Error', error);
      await ctx.reply('❌ Sorry, I had trouble seeing that photo.');
    }
  }

  async handleVoice(ctx) {
    try {
      const voice = ctx.message.voice;
      logger.info(`Received voice memo: ${voice.file_id} (${voice.duration}s)`);
      
      await ctx.sendChatAction('typing');
      
      // 1. Get file link from Telegram
      const link = await ctx.telegram.getFileLink(voice.file_id);
      
      // 2. Download the file
      const response = await fetch(link.href);
      if (!response.ok) throw new Error(`Failed to download voice memo: ${response.statusText}`);
      
      const buffer = await response.arrayBuffer();
      const audioBase64 = Buffer.from(buffer).toString('base64');
      
      // 3. Process with Brain
      const aiResponse = await this.withTyping(ctx, () => 
        this.brain.process({ 
          audioBase64, 
          mimeType: voice.mime_type || 'audio/ogg' 
        }, (status) => {
          logger.info(`Status update: ${status}`);
        })
      );
      
      await this.safeReply(ctx, aiResponse);
    } catch (error) {
      logger.error('Voice Processing Error', error);
      await ctx.reply('❌ Sorry, I had trouble hearing that voice memo.');
    }
  }

  async start() {
    this.telegraf.launch();
    logger.info('Telegram Bot started');
  }

  async stop() {
    this.telegraf.stop();
  }
}

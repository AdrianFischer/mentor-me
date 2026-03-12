import { Telegraf, Markup } from 'telegraf';
import { logger } from './logger.js';
import { exec } from 'child_process';
import path from 'path';

export class BotService {
  constructor(config, brain) {
    this.token = config.telegramToken;
    this.authorizedUserIds = config.authorizedUserIds;
    this.brain = brain;
    this.telegraf = new Telegraf(this.token, {
      handlerTimeout: 300000 // 5 minutes for heavy thinking
    });
    this.setupHandlers();
  }

  setupHandlers() {
    // Security Middleware
    this.telegraf.use(async (ctx, next) => {
      const userId = ctx.from?.id;
      
      // Discovery Mode: Always log the User ID
      if (userId) {
        logger.info(`[SECURITY] Access attempt from User ID: ${userId} (${ctx.from.username || 'unknown'})`);
      }

      if (this.isAuthorized(userId)) {
        return next();
      }

      logger.warn(`[SECURITY] Blocked unauthorized access from User ID: ${userId}`);
      // Only reply to first message to avoid spamming the attacker back
      if (ctx.message?.text === '/start') {
        await ctx.reply('🔒 *Access Denied.*\nThis is a private AI assistant.', { parse_mode: 'Markdown' });
      }
    });

    this.telegraf.start((ctx) => this.handleStart(ctx));
    this.telegraf.help((ctx) => this.handleHelp(ctx));
    
    // Model Selection Command
    this.telegraf.command('model', (ctx) => this.handleModelCommand(ctx));
    
    // Workflow Commands
    this.telegraf.command('start_day', (ctx) => this.handleWorkflow(ctx, 'start-day'));
    this.telegraf.command('end_day', (ctx) => this.handleWorkflow(ctx, 'end-day'));
    this.telegraf.command('pause', (ctx) => this.handlePauseResume(ctx, 'pause'));
    this.telegraf.command('resume', (ctx) => this.handlePauseResume(ctx, 'resume'));
    this.telegraf.command('reflect', (ctx) => this.handleReflect(ctx));
    this.telegraf.command('improve', (ctx) => this.handleImprove(ctx));
    
    // Clear History Command
    this.telegraf.command('clear', async (ctx) => {
      this.brain.gemini.clearHistory();
      await ctx.reply('🧹 My chat memory has been wiped clean. What would you like to discuss?');
    });
    
    // Actions for model selection
    this.telegraf.action('set_model_instant', (ctx) => this.handleSetModel(ctx, 'instant'));
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

  isAuthorized(userId) {
    // If no whitelist is defined, allow (useful for initial setup)
    if (!this.authorizedUserIds || this.authorizedUserIds.length === 0) {
      return true;
    }
    return this.authorizedUserIds.includes(userId);
  }

  async handleStart(ctx) {
    await this.safeReply(ctx, '👋 Welcome to Assisted Intelligence! I am your AI agent. I can help you manage tasks and remember important facts.\n\nTry saying "Show my tasks" or "Remember I have a flight at 10 AM".');
  }

  async handleHelp(ctx) {
    await this.safeReply(ctx, '📖 *Assisted Intelligence Help*\n\nUsage examples:\n• "Show my tasks"\n• "Mark task 1 as completed"\n• "Remember that I like blue"\n• /model - Switch between Instant, Fast, and Smart models\n• /start_day - Analyze today\'s priorities\n• /end_day - Summarize wins and plan tomorrow\n• /pause & /resume - Control background routines\n• /reflect - Manually trigger context reflection and learning.\n• /improve - Run an autonomous improvement process to fix recent issues.');
  }

  async handleWorkflow(ctx, type) {
    try {
      logger.info(`Starting Workflow: ${type}`);
      await ctx.sendChatAction('typing');
      
      const prompt = type === 'start-day' 
        ? "[System: User is starting their day. Please analyze their current tasks and suggest the top 3 priorities for today based on their long-term goals and boss's expectations. IMPORTANT: You MUST reply in the exact same language the user has been using with you.]"
        : "[System: User is ending their day. Please summarize their wins, check for any overdue tasks, suggest a rough plan for tomorrow, AND MUST explicitly use the pause_routines tool to pause all background activity so they don't run overnight. IMPORTANT: You MUST reply in the exact same language the user has been using with you.]";

      const statusUpdater = this._createStatusUpdater(ctx);
      const response = await this.withTyping(ctx, () => 
        this.brain.process(prompt, async (status) => {
          await statusUpdater.update(status);
        })
      );
      
      const messageId = await statusUpdater.clear();
      await this.safeReply(ctx, response, messageId);
    } catch (error) {
      logger.error('Workflow Error', error);
      await ctx.reply(`❌ Sorry, I encountered an error during your ${type} workflow.`);
    }
  }

  async handleReflect(ctx) {
    try {
      await ctx.sendChatAction('typing');
      await ctx.reply('🧠 <b>Context Reflection:</b> Reviewing recent interactions and updating global knowledge base...', { parse_mode: 'HTML' });
      const summary = await this.brain.reflect();
      await this.safeReply(ctx, summary);
    } catch (error) {
      logger.error('Reflection command error', error);
      await ctx.reply('❌ Failed to run self-reflection.');
    }
  }

  async handleImprove(ctx) {
    try {
      logger.info('Dispatching Conductor Workflow: improve');
      await ctx.reply('🛠️ <b>Continuous Improvement:</b> Dispatching background agent to analyze recent issues and propose architectural or codebase fixes...', { parse_mode: 'HTML' });
      
      const chatHistoryPath = path.resolve(__dirname, 'data', 'chat_history.json');
      const prompt = `Please review recent system logs in logs/routines/, test failures, and our recent chat history located at ${chatHistoryPath}. Identify one area of improvement or a recent bug the user mentioned, formulate a plan to fix it, and execute the fix autonomously. Finally, update GEMINI.md with your findings.`;

      const cmd = `npx -y conductor-oss@latest spawn mentor-me "${prompt}"`;
      const workspacePath = path.resolve('..');
      
      exec(cmd, { cwd: workspacePath }, (error, stdout, stderr) => {
        if (error) {
          logger.error('Improvement Workflow Error', error);
          ctx.reply('❌ <b>Conductor Error:</b> Failed to dispatch improvement workflow. Check logs.', { parse_mode: 'HTML' });
        } else {
          logger.info('Conductor Improvement Workflow dispatched successfully.');
          ctx.reply('✅ Background Agent dispatched. You can track its progress in the Conductor dashboard (http://localhost:4747).', { parse_mode: 'HTML' });
        }
      });
    } catch (error) {
      logger.error('Improve command error', error);
      await ctx.reply('❌ Sorry, I encountered an error starting the improvement process.');
    }
  }

  
  async handlePauseResume(ctx, action) {
    try {
      if (action === 'pause') {
        const result = this.brain.routinesManager._pauseRoutines({ reason: 'Manual slash command' });
        await ctx.reply('⏸️ ' + result.message);
      } else {
        const result = this.brain.routinesManager._resumeRoutines({});
        await ctx.reply('▶️ ' + result.message);
      }
    } catch (error) {
      logger.error('Pause/Resume Error', error);
      await ctx.reply('❌ Failed to ' + action + ' routines.');
    }
  }

  async handleModelCommand(ctx) {

        await ctx.reply('🤖 *Select AI Model*\n\n• *Instant*: Gemini 2.5 Flash (Super fast)\n• *Fast*: Gemini 3 Flash (Quick responses)\n• *Smart*: Gemini 3.1 Pro (Better reasoning)', {
      parse_mode: 'Markdown',
      ...Markup.inlineKeyboard([
        [
          Markup.button.callback('💨 Instant', 'set_model_instant'),
          Markup.button.callback('⚡ Fast', 'set_model_fast'), 
          Markup.button.callback('🧠 Smart', 'set_model_smart')
        ]
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
      
      const statusUpdater = this._createStatusUpdater(ctx);
      const response = await this.withTyping(ctx, () => 
        this.brain.process(text, async (status) => {
          await statusUpdater.update(status);
        })
      );
      
      const messageId = await statusUpdater.clear();
      await this.safeReply(ctx, response, messageId);
    } catch (error) {
      logger.error('Telegram Error', error);
      await ctx.reply('❌ Sorry, something went wrong while thinking.');
    }
  }

  _createStatusUpdater(ctx) {
    let statusMsg;
    let lastStatus = '';
    let updateChain = Promise.resolve();

    return {
      update: (status) => {
        logger.info(`Status update: ${status}`);
        if (status !== lastStatus) {
          lastStatus = status;
          updateChain = updateChain.then(async () => {
            try {
              if (!statusMsg) {
                statusMsg = await ctx.reply(`<i>⏳ ${status}</i>`, { parse_mode: 'HTML' });
              } else {
                await ctx.telegram.editMessageText(ctx.chat.id, statusMsg.message_id, null, `<i>⏳ ${status}</i>`, { parse_mode: 'HTML' });
              }
            } catch (e) {
              // Ignore 'message is not modified' and similar errors
            }
          });
        }
        return updateChain;
      },
      clear: async () => {
        await updateChain;
        return statusMsg ? statusMsg.message_id : null;
      }
    };
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
  async safeReply(ctx, response, statusMsgId = null) {
    const text = typeof response === 'string' ? response : response.text;
    const imageBase64 = response.imageBase64;

    try {
      logger.info(`Outgoing to Telegram: "${text.substring(0, 100)}${text.length > 100 ? '...' : ''}" ${imageBase64 ? '[+Image]' : ''}`);
      if (imageBase64) {
        if (statusMsgId) {
          await ctx.telegram.deleteMessage(ctx.chat.id, statusMsgId).catch(() => {});
        }
        const buffer = Buffer.from(imageBase64, 'base64');
        await ctx.replyWithPhoto({ source: buffer }, { 
          caption: text.substring(0, 1024),
          parse_mode: 'HTML' 
        });
        if (text.length > 1024) {
          await this._sendChunkedText(ctx, text.substring(1024));
        }
      } else {
        await this._sendChunkedText(ctx, text, true, statusMsgId);
      }
    } catch (error) {
      logger.warn('Rich reply failed, sending as plain text.', error.message);
      await this._sendChunkedText(ctx, text, false, statusMsgId); // Final fallback to plain text
    }
  }

  async _sendChunkedText(ctx, text, useHtml = true, statusMsgId = null) {
    const maxLength = 4000;
    for (let i = 0; i < text.length; i += maxLength) {
      const chunk = text.substring(i, i + maxLength);
      try {
        if (i === 0 && statusMsgId) {
          if (useHtml) {
            await ctx.telegram.editMessageText(ctx.chat.id, statusMsgId, null, chunk, { parse_mode: 'HTML' });
          } else {
            await ctx.telegram.editMessageText(ctx.chat.id, statusMsgId, null, chunk);
          }
        } else {
          if (useHtml) {
            await ctx.reply(chunk, { parse_mode: 'HTML' });
          } else {
            await ctx.reply(chunk);
          }
        }
      } catch (e) {
        logger.warn('Chunk reply failed, falling back to plain text/new message', e.message);
        if (i === 0 && statusMsgId) {
           await ctx.telegram.deleteMessage(ctx.chat.id, statusMsgId).catch(() => {});
        }
        await ctx.reply(chunk);
      }
    }
  }

  async handlePhoto(ctx) {
    const photos = ctx.message.photo;
    if (!photos || photos.length === 0) return;
    
    // Highest resolution is the last one in the array
    const photo = photos[photos.length - 1];
    return this._downloadAndProcessMedia(ctx, photo.file_id, 'image/jpeg', ctx.message.caption);
  }

  async handleVoice(ctx) {
    const voice = ctx.message.voice;
    return this._downloadAndProcessMedia(ctx, voice.file_id, voice.mime_type || 'audio/ogg');
  }

  /**
   * Generic helper to download media from Telegram and pass it to the AI brain.
   */
  async _downloadAndProcessMedia(ctx, fileId, mimeType, text = null) {
    try {
      logger.info(`Processing media: ${fileId} (${mimeType})`);
      
      const statusUpdater = this._createStatusUpdater(ctx);
      const response = await this.withTyping(ctx, async () => {
        // 1. Get file link from Telegram
        const link = await ctx.telegram.getFileLink(fileId);
        
        // 2. Download the file
        const download = await fetch(link.href);
        if (!download.ok) throw new Error(`Failed to download media: ${download.statusText}`);
        
        const buffer = await download.arrayBuffer();
        const base64 = Buffer.from(buffer).toString('base64');
        
        // 3. Process with Brain
        const input = mimeType.startsWith('image') 
          ? { imageBase64: base64, mimeType, text }
          : { audioBase64: base64, mimeType };
          
        return this.brain.process(input, async (status) => {
          await statusUpdater.update(status);
        });
      });
      
      const messageId = await statusUpdater.clear();
      await this.safeReply(ctx, response, messageId);
    } catch (error) {
      logger.error('Media Processing Error', error);
      const type = mimeType.startsWith('image') ? 'photo' : 'voice memo';
      await ctx.reply(`❌ Sorry, I had trouble processing that ${type}.`);
    }
  }

  async start() {
    this.telegraf.launch();
    logger.info('Telegram Bot started');
  }

  async stop() {
    this.telegraf.stop();
  }

  /**
   * Proactively sends a message to an authorized user.
   */
  async sendMessage(userId, text) {
    if (!this.isAuthorized(userId)) {
      logger.warn(`Attempted to send proactive message to unauthorized ID: ${userId}`);
      return;
    }

    try {
      const maxLength = 4000;
      for (let i = 0; i < text.length; i += maxLength) {
        const chunk = text.substring(i, i + maxLength);
        await this.telegraf.telegram.sendMessage(userId, chunk, { parse_mode: 'HTML' }).catch(async (e) => {
          logger.warn(`HTML proactive send failed, falling back to plain text`, e.message);
          await this.telegraf.telegram.sendMessage(userId, chunk);
        });
      }
    } catch (error) {
      logger.error(`Failed to send proactive message to ${userId}`, error);
    }
  }
}

import fs from 'fs';
import path from 'path';
import { logger } from './logger.js';
import { RoutinesManager } from './routines_manager.js';
import { GithubTools } from './github_tools.js';

export class AgentBrain {
  constructor(services = {}) {
    this.mcp = services.mcp;
    this.gemini = services.gemini;
    this.bot = services.bot;
    this.routinesManager = new RoutinesManager();
    this.githubTools = new GithubTools();
  }

  setModel(type) {
    return this.gemini.setModel(type);
  }

  /**
   * Main entry point for user input.
   * @param {string|Object} input - String for text, or { audioBase64, mimeType } for voice.
   * @param {Function} onStatus - Optional callback for status updates.
   */
  async process(input, onStatus = () => {}) {
    try {
      const prompt = this._buildPrompt(input);
      const isMultimodal = Array.isArray(prompt);
      logger.info(`Processing ${isMultimodal ? 'Multimodal' : 'Text'}: ${isMultimodal ? '[Media Data]' : `"${prompt}"`}`);

      onStatus('Discovering tools...');
      const allTools = await this._gatherTools();

      onStatus('Thinking...');
      let { text: responseText, toolCalls } = await this.gemini.process(prompt, allTools);

      const executedTools = [];
      let mediaOutput = null;

      while (toolCalls && toolCalls.length > 0) {
        for (const call of toolCalls) {
          onStatus(`Executing ${call.name}...`);
          logger.info(`Calling tool: ${call.name} with ${JSON.stringify(call.args)}`);
          
          const result = await this._executeTool(call);
          
          executedTools.push(call.name);

          // Standardized media protocol: if tool returns a 'media' object
          if (result && result.media && result.media.base64 && result.result === 'success') {
            mediaOutput = result.media;
          }

          onStatus(`Analyzing result of ${call.name}...`);
          const summary = await this.gemini.processToolResult(call.name, result);
          responseText = summary.text;
          toolCalls = summary.toolCalls;
        }
      }

      responseText = await this._ensureTextResponse(responseText, executedTools, onStatus);

      if (mediaOutput) {
        return { text: responseText, ...mediaOutput };
      }

      return responseText;
    } catch (error) {
      logger.error('Brain Error', error);
      return `❌ Sorry, I had trouble processing that: ${error.message}`;
    }
  }

  _buildPrompt(input) {
    if (typeof input === 'string') {
      return input;
    } else if (input.audioBase64) {
      return [
        { inlineData: { data: input.audioBase64, mimeType: input.mimeType || 'audio/ogg' } },
        { text: "The user sent a voice memo. Please listen and respond or execute tools as requested. IMPORTANT: Always provide a textual response summarizing exactly what you did, including names of items created or updated." }
      ];
    } else if (input.imageBase64) {
      return [
        { inlineData: { data: input.imageBase64, mimeType: input.mimeType || 'image/jpeg' } },
        { text: input.text || "The user sent an image. Please analyze it and respond or execute tools as requested." }
      ];
    } else {
      throw new Error('Invalid input format to Brain.process()');
    }
  }

  async _gatherTools() {
    const mcpTools = await this.mcp.discoverTools();
    const localTools = this.routinesManager.getTools();
    const ghTools = this.githubTools.getTools();

    return [...mcpTools, ...localTools, ...ghTools];
  }

  async _executeTool(call) {
    const localToolNames = this.routinesManager.getTools().map(t => t.name);
    const ghToolNames = this.githubTools.getTools().map(t => t.name);
    
    if (localToolNames.includes(call.name)) {
      return this.routinesManager.executeTool(call);
    } else if (ghToolNames.includes(call.name)) {
      return this.githubTools.executeTool(call);
    } else {
      return await this.mcp.callTool(call.name, call.args);
    }
  }

  async _ensureTextResponse(responseText, executedTools, onStatus) {
    let finalResponseText = responseText;
    
    // Final summary turn - if tools were called but no text was generated
    if (executedTools.length > 0 && (!finalResponseText || finalResponseText.trim() === '')) {
      onStatus('Summarizing actions...');
      logger.info('Tools were executed but no response text was provided. Forcing summary turn.');
      
      const summary = await this.gemini.process("Please summarize what you just did for me in a human-friendly, professional tone, listing the key items you've added or updated.");
      finalResponseText = summary.text;
    }

    // Catch-all fallback if still empty
    if (!finalResponseText || finalResponseText.trim() === '') {
      if (executedTools.length > 0) {
        finalResponseText = "✅ I've processed your request and updated your task list accordingly. Is there anything else I can help with?";
      } else {
        logger.warn('Gemini returned an empty response. Using fallback.');
        finalResponseText = "I've handled that for you. What's next on our agenda?";
      }
    }

    return finalResponseText;
  }
}

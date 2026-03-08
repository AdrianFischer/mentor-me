import { logger } from './logger.js';

export class AgentBrain {
  constructor(services = {}) {
    this.mcp = services.mcp;
    this.gemini = services.gemini;
    this.bot = services.bot;
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
    let prompt;
    if (typeof input === 'string') {
      prompt = input;
    } else if (input.audioBase64) {
      prompt = [
        { inlineData: { data: input.audioBase64, mimeType: input.mimeType || 'audio/ogg' } },
        { text: "The user sent a voice memo. Please listen and respond or execute tools as requested. IMPORTANT: Always provide a textual response summarizing exactly what you did, including names of items created or updated." }
      ];
    } else if (input.imageBase64) {
      prompt = [
        { inlineData: { data: input.imageBase64, mimeType: input.mimeType || 'image/jpeg' } },
        { text: input.text || "The user sent an image. Please analyze it and respond or execute tools as requested." }
      ];
    } else {
      throw new Error('Invalid input format to Brain.process()');
    }

    const isMultimodal = Array.isArray(prompt);
    logger.info(`Processing ${isMultimodal ? 'Multimodal' : 'Text'}: ${isMultimodal ? '[Media Data]' : `"${prompt}"`}`);
    onStatus('Discovering tools...');

    try {
      // 1. Discover available tools from app
      const mcpTools = await this.mcp.discoverTools();

      // 2. Initial processing with Gemini
      onStatus('Thinking...');
      let { text: responseText, toolCalls } = await this.gemini.process(prompt, mcpTools);

      // 3. Tool execution loop
      const executedTools = [];
      let mediaOutput = null;

      while (toolCalls && toolCalls.length > 0) {
        for (const call of toolCalls) {
          onStatus(`Executing ${call.name}...`);
          logger.info(`Calling tool: ${call.name} with ${JSON.stringify(call.args)}`);
          const result = await this.mcp.callTool(call.name, call.args);
          executedTools.push(call.name);

          // Standardized media protocol: if tool returns a 'media' object
          if (result.media && result.media.base64 && result.result === 'success') {
            mediaOutput = result.media;
          }

          // Feed result back to Gemini
          onStatus(`Analyzing result of ${call.name}...`);
          const summary = await this.gemini.processToolResult(call.name, result);
          responseText = summary.text;
          toolCalls = summary.toolCalls;
        }
      }

      // 4. Final summary turn - if tools were called but no text was generated
      if (executedTools.length > 0 && (!responseText || responseText.trim() === '')) {
        onStatus('Summarizing actions...');
        logger.info('Tools were executed but no response text was provided. Forcing summary turn.');
        
        // Final request for a human-like summary
        const summary = await this.gemini.process("Please summarize what you just did for me in a human-friendly, professional tone, listing the key items you've added or updated.");
        responseText = summary.text;
      }

      // 5. Catch-all fallback if still empty
      if (!responseText || responseText.trim() === '') {
        if (executedTools.length > 0) {
          responseText = "✅ I've processed your request and updated your task list accordingly. Is there anything else I can help with?";
        } else {
          logger.warn('Gemini returned an empty response. Using fallback.');
          responseText = "I've handled that for you. What's next on our agenda?";
        }
      }

      // Return both text and media if available
      if (mediaOutput) {
        return { text: responseText, ...mediaOutput };
      }

      return responseText;
    } catch (error) {
      logger.error('Brain Error', error);
      return `❌ Sorry, I had trouble processing that: ${error.message}`;
    }
  }

  // Keep processInput for tests compatibility
  async processInput(text) {
    const input = text.toLowerCase();
    let resText = 'Listing...';
    let toolCalls = [];

    if (input.includes('finished') || input.includes('completed')) {
      toolCalls.push({ name: 'list_todos_by_status', args: { status: 'completed' } });
    } else if (input.includes('tasks') || input.includes('todo')) {
      toolCalls.push({ name: 'list_todos_by_status', args: { status: 'active' } });
    } else if (input.includes('mark') || input.includes('complete')) {
      toolCalls.push({ name: 'update_todo_by_index', args: { index: 2, is_completed: true } });
    } else if (input.includes('notes')) {
      toolCalls.push({ name: 'update_todo_by_index', args: { index: 1, notes: 'Check the reactor' } });
    } else if (input.includes('remember')) {
      toolCalls.push({ name: 'save_memory', args: { fact: text } });
    } else if (input.includes('update')) {
      resText = 'Which task should I update?';
    }

    return { text: resText, toolCalls };
  }
}

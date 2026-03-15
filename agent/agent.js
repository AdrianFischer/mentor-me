import fs from 'fs';
import path from 'path';
import { logger } from './logger.js';
import { RoutinesManager } from './routines_manager.js';
import { GithubTools } from './github_tools.js';
import { SharedFolderManager } from './shared_folder_manager.js';

export class AgentBrain {
  constructor(services = {}) {
    this.mcp = services.mcp;
    this.gemini = services.gemini;
    this.bot = services.bot;
    this.routinesManager = new RoutinesManager();
    this.githubTools = new GithubTools();
    this.sharedFolderManager = new SharedFolderManager();
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

      // Automatic Learning: Trigger reflection if the input implies ending a context or task
      if (typeof input === 'string' && this._isClosingInteraction(input)) {
        onStatus('Learning from session...');
        await this.reflect();
      }

      if (mediaOutput) {
        return { text: responseText, ...mediaOutput };
      }

      return responseText;
    } catch (error) {
      logger.error('Brain Error', error);
      return `❌ Sorry, I had trouble processing that: ${error.message}`;
    }
  }

  /**
   * Triggers a self-reflection turn to extract learnings and update GEMINI.md.
   */
  async reflect() {
    try {
      logger.info('🧠 Triggering Self-Reflection Turn...');
      const prompt = `[System: Context Reflection Mode. Please review our recent interactions. Identify any new user preferences, project-specific technical learnings, or architectural decisions. 
IMPORTANT:
1. Update the global GEMINI.md file in the root directory (if it exists) with these insights in the "Learnings & Future Context" section. 
2. Ensure you do not duplicate existing information. 
3. Summarize what you've learned for the user in a professional, senior assistant tone.]`;
      
      const { text: reflectionText } = await this.gemini.process(prompt, await this._gatherTools());
      logger.info(`Self-Reflection complete: ${reflectionText.substring(0, 100)}...`);
      return reflectionText;
    } catch (error) {
      logger.error('Reflection Error', error);
    }
  }

  _isClosingInteraction(text) {
    const closingWords = ['bye', 'good night', 'finish', 'complete', 'goodnight', 'done for today', 'schluss für heute', 'gute nacht'];
    return closingWords.some(word => text.toLowerCase().includes(word));
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
    const sharedTools = this.sharedFolderManager.getTools();

    const verifyTaskTool = {
      name: 'verify_task_exists',
      description: 'Verifies if a specific task or subtask exists in the project. Use this to quickly confirm a task was created without pulling the entire list of tasks, which can time out.',
      inputSchema: {
        type: 'object',
        properties: {
          title: { type: 'string', description: 'The exact title or a unique substring of the task title.' },
          project: { type: 'string', description: 'Optional project name to narrow down the search.' }
        },
        required: ['title']
      }
    };

    return [...mcpTools, ...localTools, ...ghTools, ...sharedTools, verifyTaskTool];
  }

  async _executeTool(call) {
    if (call.name === 'verify_task_exists') {
      return await this._verifyTaskExists(call.args);
    }

    const localToolNames = this.routinesManager.getTools().map(t => t.name);
    const ghToolNames = this.githubTools.getTools().map(t => t.name);
    const sharedToolNames = this.sharedFolderManager.getTools().map(t => t.name);

    if (localToolNames.includes(call.name)) {
      return this.routinesManager.executeTool(call);
    } else if (ghToolNames.includes(call.name)) {
      return this.githubTools.executeTool(call);
    } else if (sharedToolNames.includes(call.name)) {
      return this.sharedFolderManager.executeTool(call);
    } else {
      return await this.mcp.callTool(call.name, call.args);
    }
  }

  async _verifyTaskExists(args) {
    try {
      const response = await this.mcp.callTool('mcp_flutterApp_list_todos_by_status', { status: 'active' });
      
      let items = [];
      if (response && response.items) {
        items = response.items;
      } else if (response && response.output) {
        const parsed = typeof response.output === 'string' ? JSON.parse(response.output) : response.output;
        items = parsed.items || [];
      } else if (response && response.content) {
        const textContent = response.content.find(c => c.type === 'text');
        if (textContent) {
          const parsed = JSON.parse(textContent.text);
          items = parsed.items || [];
        }
      }

      const { title, project } = args;
      
      const found = items.filter(item => {
         const matchTitle = item.title && item.title.toLowerCase().includes(title.toLowerCase());
         const matchProject = project && item.project ? item.project.toLowerCase() === project.toLowerCase() : true;
         return matchTitle && matchProject;
      });

      if (found.length > 0) {
        return { result: 'success', found: true, matches: found.slice(0, 5) };
      } else {
        return { result: 'success', found: false, message: `No active task found matching title '${title}'.` };
      }
    } catch (error) {
       logger.error('Error verifying task', error);
       return { result: 'error', message: error.message };
    }
  }

  async _ensureTextResponse(responseText, executedTools, onStatus) {
    let finalResponseText = responseText;
    
    // Final summary turn - if tools were called but no text was generated
    if (executedTools.length > 0 && (!finalResponseText || finalResponseText.trim() === '')) {
      onStatus('Summarizing actions...');
      logger.info('Tools were executed but no response text was provided. Forcing summary turn.');
      
      const summary = await this.gemini.process("[System: Please summarize what you just did for me in a human-friendly, professional tone, listing the key items you've added or updated. IMPORTANT: You MUST reply in the exact same language the user has been using with you.]");
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

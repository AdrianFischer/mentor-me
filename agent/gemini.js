import { GoogleGenerativeAI } from "@google/generative-ai";
import { logger } from './logger.js';

export class GeminiService {
  constructor(config) {
    this.apiKey = config.geminiApiKey;
    this.genAI = new GoogleGenerativeAI(this.apiKey);
    
    this.models = {
      smart: "gemini-3.1-pro-preview",
      fast: "gemini-2.0-flash"
    };
    
    this.modelName = this.models.smart;
    this.systemInstruction = `You are the 'Assisted Intelligence' Senior Executive Assistant. 
Your goal is to manage the user's tasks and projects with extreme professional competence and a helpful, human-like tone.

CONSTRAINTS:
1. Always provide a textual response summarizing your actions.
2. Use clear HTML (<b>bold</b>, <i>italic</i>, <code>code</code>) to make information digestible. 
   - Use <b>...</b> for bold.
   - Use <i>...</i> for italics.
   - For bullet points, use the '•' character at the start of the line.
3. If you add or update tasks, mention them by name so the user knows you understood correctly.
4. If a user sends a long voice memo, act as a 'Minute Taker'—summarize the key points and confirm which actions you took.
5. Never respond with just tool names. Respond like a person who just finished a task for their boss.`;
    this.history = [];
    this.availableTools = [];
    this.tools = []; // Formatted for Gemini
  }

  setModel(type) {
    if (this.models[type]) {
      this.modelName = this.models[type];
      logger.info(`Switched to ${type} model: ${this.modelName}`);
      return true;
    }
    return false;
  }

  updateTools(mcpTools) {
    this.availableTools = mcpTools.map(t => t.name);
    this.tools = mcpTools.map(t => ({
      functionDeclarations: [{
        name: t.name,
        description: t.description,
        parameters: t.inputSchema
      }]
    }));
  }

  addToHistory(role, parts) {
    if (this.history.length === 0 && role !== 'user') return;
    this.history.push({ role, parts });
    if (this.history.length > 20) {
      this.history = this.history.slice(-20);
      if (this.history[0].role !== 'user') this.history.shift();
    }
  }

  async process(prompt, mcpTools = []) {
    this.updateTools(mcpTools);
    const chat = this._getChatSession();

    const result = await chat.sendMessage(prompt);
    return this._handleResponse(chat, result.response);
  }

  async processToolResult(toolName, resultData) {
    const chat = this._getChatSession();

    const result = await chat.sendMessage([
      {
        functionResponse: {
          name: toolName,
          response: { result: resultData }
        }
      }
    ]);

    return this._handleResponse(chat, result.response);
  }

  _getChatSession() {
    const model = this.genAI.getGenerativeModel({
      model: this.modelName,
      systemInstruction: this.systemInstruction,
      tools: this.tools
    });

    // Ensure history starts with 'user'
    const cleanHistory = [...this.history];
    while (cleanHistory.length > 0 && cleanHistory[0].role !== 'user') {
      cleanHistory.shift();
    }

    return model.startChat({
      history: cleanHistory,
    });
  }

  async _handleResponse(chat, response) {
    this.history = this._cleanHistory(await chat.getHistory());
    
    if (!response.candidates || response.candidates.length === 0) {
      return { text: "", toolCalls: [] };
    }
    
    const candidates = response.candidates[0];
    if (!candidates.content || !candidates.content.parts) {
      return { text: "", toolCalls: [] };
    }
    
    const parts = candidates.content.parts;
    const toolCalls = parts
      .filter(p => p.functionCall)
      .map(p => ({
        name: p.functionCall.name,
        args: p.functionCall.args
      }));

    const text = parts
      .filter(p => p.text)
      .map(p => p.text)
      .join('\n');

    return { text, toolCalls };
  }

  _cleanHistory(history) {
    return history.map(turn => ({
      role: turn.role,
      parts: turn.parts.map(part => {
        if (part.inlineData) {
          const type = part.inlineData.mimeType.startsWith('audio') ? 'Voice Memo' : 'Image';
          return { text: `[Processed ${type}]` };
        }
        return part;
      })
    }));
  }

  async safeProcess(prompt) {
    try {
      return await this.process(prompt);
    } catch (error) {
      logger.error('Gemini Error', error);
      return { text: `❌ Gemini Error: ${error.message}`, toolCalls: [] };
    }
  }
}

import { GoogleGenerativeAI } from "@google/generative-ai";
import { logger } from './logger.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export class GeminiService {
  constructor(config) {
    this.apiKey = config.geminiApiKey;
    this.genAI = new GoogleGenerativeAI(this.apiKey);
    
        this.models = {
      smart: "gemini-3.1-pro-preview",
      fast: "gemini-3-flash-preview", // User preferred fast/preview model
      instant: "gemini-2.5-flash"
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
5. Never respond with just tool names. Respond like a person who just finished a task for their boss.
6. You have direct access to the GitHub CLI tools. Use them to fetch pull requests, read PR comments, or check Cloud Run statuses whenever the user asks about GitHub or CI/CD.`;
    this.historyFile = path.join(__dirname, 'data', 'chat_history.json');
    this.history = this._loadHistory();
    this.availableTools = [];
    this.tools = []; // Formatted for Gemini
  }

  
  _loadHistory() {
    try {
      if (fs.existsSync(this.historyFile)) {
        return JSON.parse(fs.readFileSync(this.historyFile, 'utf-8'));
      }
    } catch (e) {
      logger.error('Failed to load chat history', e);
    }
    return [];
  }

  _saveHistory() {
    try {
      const dir = path.dirname(this.historyFile);
      if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
      fs.writeFileSync(this.historyFile, JSON.stringify(this.history, null, 2));
    } catch (e) {
      logger.error('Failed to save chat history', e);
    }
  }


  clearHistory() {
    this.history = [];
    this._saveHistory();
    logger.info('Chat history cleared.');
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
    this._saveHistory();
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
    let newHistory = this._cleanHistory(await chat.getHistory());
    
    // Truncate to the last 20 messages to maintain context limit
    if (newHistory.length > 20) {
      newHistory = newHistory.slice(-20);
      if (newHistory.length > 0 && newHistory[0].role !== 'user') {
        newHistory.shift();
      }
    }
    
    this.history = newHistory;
    this._saveHistory();
    
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
    if (!history || history.length === 0) return [];
    
    return history.map(turn => {
      // Only check turns that have inlineData
      const hasInlineData = turn.parts.some(p => p.inlineData);
      if (!hasInlineData) return turn;

      return {
        role: turn.role,
        parts: turn.parts.map(part => {
          if (part.inlineData) {
            const type = part.inlineData.mimeType.startsWith('audio') ? 'Voice Memo' : 'Image';
            return { text: `[Processed ${type}]` };
          }
          return part;
        })
      };
    });
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

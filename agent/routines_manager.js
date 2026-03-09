import fs from 'fs';
import path from 'path';
import { logger } from './logger.js';

export class RoutinesManager {
  constructor(routinesDir = path.resolve('../data/routines')) {
    this.routinesDir = routinesDir;
    if (!fs.existsSync(this.routinesDir)) {
      fs.mkdirSync(this.routinesDir, { recursive: true });
    }
  }

  getTools() {
    return [
      {
        name: 'list_routines',
        description: 'Lists all currently configured autonomous routines and their schedules.',
        inputSchema: { type: 'object', properties: {} }
      },
      {
        name: 'update_routine',
        description: 'Creates or updates an autonomous routine definition. Use this to change frequency, tasks, or add "learned" context for next runs.',
        inputSchema: {
          type: 'object',
          properties: {
            filename: { type: 'string', description: 'The filename (e.g., daily_cleanup.json).' },
            name: { type: 'string', description: 'Human readable name.' },
            execute_every_seconds: { type: 'number', description: 'Interval in seconds.' },
            task: { type: 'string', description: 'The task description for Gemini CLI.' },
            context: { type: 'string', description: 'Context and learned strategies for the routine.' },
            timeout: { type: 'number', description: 'Max runtime in seconds.' }
          },
          required: ['filename', 'name', 'task', 'execute_every_seconds']
        }
      },
      {
        name: 'delete_routine',
        description: 'Removes an autonomous routine.',
        inputSchema: {
          type: 'object',
          properties: {
            filename: { type: 'string' }
          },
          required: ['filename']
        }
      }
    ];
  }

  async executeTool(call) {
    if (call.name === 'list_routines') {
      return this._listRoutines();
    } else if (call.name === 'update_routine') {
      return this._updateRoutine(call.args);
    } else if (call.name === 'delete_routine') {
      return this._deleteRoutine(call.args);
    }
    throw new Error(`Unknown tool: ${call.name}`);
  }

  _listRoutines() {
    try {
      if (!fs.existsSync(this.routinesDir)) return { result: 'success', routines: [] };
      const files = fs.readdirSync(this.routinesDir).filter(f => f.endsWith('.json'));
      const routines = files.map(f => {
        try {
          const content = JSON.parse(fs.readFileSync(path.join(this.routinesDir, f), 'utf-8'));
          return { filename: f, ...content };
        } catch (err) {
          logger.error(`Error reading routine ${f}`, err);
          return { filename: f, error: 'Invalid JSON' };
        }
      });
      return { result: 'success', routines };
    } catch (e) {
      return { result: 'error', message: e.message };
    }
  }

  _updateRoutine(args) {
    try {
      const filePath = path.join(this.routinesDir, args.filename);
      const data = { ...args };
      delete data.filename;
      
      fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
      return { result: 'success', message: `Routine ${args.filename} updated successfully.` };
    } catch (e) {
      return { result: 'error', message: e.message };
    }
  }

  _deleteRoutine(args) {
    try {
      const filePath = path.join(this.routinesDir, args.filename);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
        return { result: 'success', message: `Routine ${args.filename} deleted.` };
      }
      return { result: 'error', message: 'File not found.' };
    } catch (e) {
      return { result: 'error', message: e.message };
    }
  }
}

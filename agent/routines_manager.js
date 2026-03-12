import fs from 'fs';
import path from 'path';
import { logger } from './logger.js';

export class RoutinesManager {
  constructor(routinesDir = path.resolve('../data/routines'), logsDir = path.resolve('../logs/routines')) {
    this.routinesDir = routinesDir;
    this.logsDir = logsDir;
    if (!fs.existsSync(this.routinesDir)) {
      fs.mkdirSync(this.routinesDir, { recursive: true });
    }
    if (!fs.existsSync(this.logsDir)) {
      fs.mkdirSync(this.logsDir, { recursive: true });
    }
  }

  getTools() {
    return [

      {
        name: 'pause_routines',
        description: 'Pauses all background autonomous routines from running (e.g., when the user goes to sleep or asks to pause).',
        inputSchema: {
          type: 'object',
          properties: {
            reason: { type: 'string', description: 'Optional reason for pausing.' }
          }
        }
      },
      {
        name: 'resume_routines',
        description: 'Resumes all background autonomous routines if they were previously paused.',
        inputSchema: { type: 'object', properties: {} }
      },
      {
        name: 'get_routines_status',
        description: 'Checks whether background routines are currently paused or running.',
        inputSchema: { type: 'object', properties: {} }
      },
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
            timeout: { type: 'number', description: 'Max runtime in seconds.' },
            target_folder: { type: 'string', description: 'Optional. Restricts the agent to this specific directory.' },
            target_file: { type: 'string', description: 'Optional. Restricts the agent to a single file.' },
            enable_websearch: { type: 'boolean', description: 'If true, gives the agent google_web_search capabilities.' }
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
      },
      {
        name: 'get_active_tasks_and_logs',
        description: 'Checks which background routines are currently running and returns their latest log output so you can report progress to the user.',
        inputSchema: {
          type: 'object',
          properties: {}
        }
      },
      {
        name: 'get_recent_routine_logs',
        description: 'Reads the log file of recently executed background tasks. Use this to see what a completed routine actually did.',
        inputSchema: {
          type: 'object',
          properties: {
            routine_name: { type: 'string', description: 'Optional. Filter to a specific routine name.' },
            lines: { type: 'number', description: 'Number of lines to read from the end of the log (default 50).' }
          }
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
    } else if (call.name === 'get_active_tasks_and_logs') {
      return this._getActiveTasksAndLogs(call.args);
    
    } else if (call.name === 'pause_routines') {
      return this._pauseRoutines(call.args);
    } else if (call.name === 'resume_routines') {
      return this._resumeRoutines(call.args);
    } else if (call.name === 'get_routines_status') {
      return this._getRoutinesStatus(call.args);
} else if (call.name === 'get_recent_routine_logs') {
      return this._getRecentRoutineLogs(call.args);
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



  
  _pauseRoutines(args) {
    try {
      const stateFile = path.join(this.logsDir, 'watchdog_state.json');
      const state = { paused: true, reason: args.reason || 'Manual pause', timestamp: new Date().toISOString() };
      fs.writeFileSync(stateFile, JSON.stringify(state, null, 2));
      return { result: 'success', message: 'Background routines have been paused.' };
    } catch (e) {
      return { result: 'error', message: e.message };
    }
  }

  _resumeRoutines(args) {
    try {
      const stateFile = path.join(this.logsDir, 'watchdog_state.json');
      if (fs.existsSync(stateFile)) {
        const state = JSON.parse(fs.readFileSync(stateFile, 'utf8'));
        state.paused = false;
        state.resumed_at = new Date().toISOString();
        fs.writeFileSync(stateFile, JSON.stringify(state, null, 2));
      }
      return { result: 'success', message: 'Background routines have been resumed.' };
    } catch (e) {
      return { result: 'error', message: e.message };
    }
  }

  _getRoutinesStatus(args) {
    try {
      const stateFile = path.join(this.logsDir, 'watchdog_state.json');
      if (fs.existsSync(stateFile)) {
        return { result: 'success', state: JSON.parse(fs.readFileSync(stateFile, 'utf8')) };
      }
      return { result: 'success', state: { paused: false } };
    } catch (e) {
      return { result: 'error', message: e.message };
    }
  }

  _readLastBytes(filePath, bytes) {

    try {
      const stats = fs.statSync(filePath);
      const size = stats.size;
      const readSize = Math.min(size, bytes);
      const buffer = Buffer.alloc(readSize);
      const fd = fs.openSync(filePath, 'r');
      fs.readSync(fd, buffer, 0, readSize, size - readSize);
      fs.closeSync(fd);
      return buffer.toString('utf-8');
    } catch (e) {
      logger.error('Error reading file tail', e);
      return 'Error reading log tail.';
    }
  }

  _getActiveTasksAndLogs(args) {
    try {
      const activeTasksFile = path.join(this.logsDir, 'active_tasks.json');
      if (!fs.existsSync(activeTasksFile)) {
        return { result: 'success', active_tasks: {}, message: 'No background tasks are currently running.' };
      }
      
      const activeTasks = JSON.parse(fs.readFileSync(activeTasksFile, 'utf-8') || '{}');
      const taskDetails = [];

      for (const [taskId, taskInfo] of Object.entries(activeTasks)) {
        let tailLog = 'No log available yet.';
        if (taskInfo.log_file && fs.existsSync(taskInfo.log_file)) {
          // Efficiently read only the last 2000 bytes
          tailLog = this._readLastBytes(taskInfo.log_file, 2000);
          if (tailLog.length === 2000) tailLog = '...' + tailLog;
        }
        
        taskDetails.push({
          id: taskId,
          routine: taskInfo.routine,
          start_time: taskInfo.start_time,
          log_tail: tailLog
        });
      }

      return { result: 'success', active_tasks: taskDetails };
    } catch (e) {
      logger.error('Error reading active tasks', e);
      return { result: 'error', message: e.message };
    }
  }

  _getRecentRoutineLogs(args) {
    try {
      const telemetryFile = path.join(this.logsDir, 'telemetry.json');
      let recentRuns = [];
      if (fs.existsSync(telemetryFile)) {
         recentRuns = JSON.parse(fs.readFileSync(telemetryFile, 'utf-8') || '[]');
      }
      
      let logsList = fs.readdirSync(this.logsDir).filter(f => f.endsWith('.log'));
      logsList.sort((a, b) => {
        return fs.statSync(path.join(this.logsDir, b)).mtimeMs - fs.statSync(path.join(this.logsDir, a)).mtimeMs;
      });

      if (args.routine_name) {
         logsList = logsList.filter(f => f.startsWith(args.routine_name.replace(/\s+/g, '_')));
      }

      if (logsList.length === 0) {
         return { result: 'success', message: 'No logs found for the specified routine.' };
      }

      const fileToRead = logsList[0]; // Most recent
      const filePath = path.join(this.logsDir, fileToRead);
      
      // Efficiently read only the last 5000 bytes (roughly 50-100 lines)
      let tail = this._readLastBytes(filePath, 5000);
      if (tail.length === 5000) tail = '...' + tail;

      return { 
        result: 'success', 
        file: fileToRead,
        recent_telemetry: recentRuns.slice(-5),
        log_tail: tail 
      };

    } catch (e) {
      logger.error('Error reading recent logs', e);
      return { result: 'error', message: e.message };
    }
  }
}

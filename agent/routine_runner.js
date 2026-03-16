import { spawn } from 'child_process';
import fs from 'fs';
import path from 'path';
import { logger } from './logger.js';

export class RoutineRunner {
  constructor(config = {}) {
    this.logsDir = config.logsDir || path.resolve('../logs/routines');
    this.geminiPath = config.geminiPath || 'gemini';
  }

  /**
   * Runs a routine in a detached subprocess.
   */
  async run(routine) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const logFile = path.join(this.logsDir, `${routine.name.replace(/\s+/g, '_')}_${timestamp}.log`);
    const timeoutSeconds = routine.timeout || 300;
    const timeoutMs = timeoutSeconds * 1000;

    let dynamicContext = '';
    
    // 1. Run optional Setup Script to get dynamic context
    if (routine.setup_script) {
      try {
        logger.info(`Running setup script for ${routine.name}: ${routine.setup_script}`);
        const scriptResult = await this._runSetupScript(routine.setup_script);
        dynamicContext = `\n\nDynamic System Context (from setup script):\n${scriptResult}`;
      } catch (err) {
        logger.warn(`Setup script failed for ${routine.name}: ${err.message}`);
        dynamicContext = `\n\nWarning: Setup script failed with error: ${err.message}`;
      }
    }

    logger.info(`Starting routine execution: ${routine.name}. Timeout: ${timeoutSeconds}s`);
    
    return new Promise((resolve) => {
      const logStream = fs.createWriteStream(logFile);
      
      // Construct command arguments
      let args = [];
      if (this.geminiPath.includes('gemini')) {
        let fullPrompt = `Context: ${routine.context || ''}${dynamicContext}\n\nTask: ${routine.task}`;

        let restrictionText = '';
        if (routine.target_file) {
          restrictionText = `\n\nCRITICAL RESTRICTION: You may ONLY read and modify the specific file: ${routine.target_file}. Do NOT touch any other files.`;
        } else if (routine.target_folder) {
          restrictionText = `\n\nCRITICAL RESTRICTION: You may ONLY operate within the specific folder: ${routine.target_folder}. Do NOT touch any files outside this folder.`;
        }
        fullPrompt += restrictionText;

        args = [
          '-p', fullPrompt,
          '-o', 'json', 
          '-y' 
        ];

        if (routine.target_folder || routine.target_file || routine.enable_websearch) {
          const policyFile = path.join(this.logsDir, `policy_${timestamp}.toml`);
          let policyContent = `# Automatically generated policy for routine: ${routine.name}
[[rule]]
toolName = "run_shell_command"
decision = "deny"
priority = 100

[[rule]]
toolName = "ask_user"
decision = "deny"
priority = 100
`;
          if (routine.enable_websearch) {
            policyContent += `
[[rule]]
toolName = "google_web_search"
decision = "allow"
priority = 200
`;
          }
          fs.writeFileSync(policyFile, policyContent);
          args.push('--policy', policyFile);
        }
      } else {
        // Fallback for test mocks or generic commands
        args = [routine.task];
        if (routine.context) args.push(routine.context);
      }

      try {
        const homeDir = process.env.HOME || process.env.USERPROFILE;
        const portStr = fs.readFileSync(path.join(homeDir, '.assisted_intelligence', 'mcp_port'), 'utf-8').trim();
        const localSettingsDir = path.resolve('..', '.gemini');
        if (!fs.existsSync(localSettingsDir)) {
          fs.mkdirSync(localSettingsDir, { recursive: true });
        }
        const localSettingsPath = path.join(localSettingsDir, 'settings.json');
        let settings = {};
        if (fs.existsSync(localSettingsPath)) {
          try {
            settings = JSON.parse(fs.readFileSync(localSettingsPath, 'utf-8'));
          } catch(e) {}
        }
        settings.mcpServers = settings.mcpServers || {};
        settings.mcpServers.flutterApp = { url: `http://127.0.0.1:${portStr}/mcp` };
        fs.writeFileSync(localSettingsPath, JSON.stringify(settings, null, 2));
      } catch (err) {
        logger.warn(`Failed to update local MCP config for routine: ${err.message}`);
      }
      
      const taskId = timestamp + '_' + Math.random().toString(36).substr(2, 5);
      
      const child = spawn(this.geminiPath, args, {
        cwd: path.resolve('..'),
        detached: true,
        stdio: ['ignore', 'pipe', 'pipe']
      });
      
      this._addActiveTask(taskId, routine.name, logFile, child.pid);


      let output = '';
      let errorOutput = '';

      child.stdout.on('data', (data) => {
        output += data.toString();
        logStream.write(data);
      });

      child.stderr.on('data', (data) => {
        errorOutput += data.toString();
        logStream.write(data);
      });

      const timer = setTimeout(() => {
        logger.warn(`Routine ${routine.name} timed out after ${timeoutSeconds}s. Sending SIGTERM for graceful exit...`);
        try {
          process.kill(-child.pid, 'SIGTERM');
        } catch (e) {
          child.kill('SIGTERM');
        }
        logStream.write('\\n[TIMEOUT_ERROR] Process signaled by Watchdog (SIGTERM) due to timeout.');
        
        // Force kill if it doesn't terminate gracefully within 15 seconds
        const forceKillTimer = setTimeout(() => {
          try {
            process.kill(-child.pid, 'SIGKILL');
            logger.warn(`Routine ${routine.name} forcefully killed (SIGKILL) after ignoring SIGTERM.`);
            logStream.write('\\n[TIMEOUT_ERROR] Process forcefully killed (SIGKILL) after ignoring SIGTERM.');
          } catch (e) {
            // It already exited
          }
        }, 15000);
        forceKillTimer.unref(); // Don't block event loop
      }, timeoutMs);

      
      child.on('close', (code) => {
        this._removeActiveTask(taskId);
        clearTimeout(timer);

        logger.info(`Routine ${routine.name} finished with code ${code}`);

        let usage = { total_tokens: 0 };
        let finalResponse = output.trim();

        if (this.geminiPath.includes('gemini') && output.trim()) {
          const lastSessionIdMatch = output.lastIndexOf('{\n  "session_id"');
          // If no session_id is found, find the first '{' and the last '}'
          // (assuming the JSON output is the main content)
          const startIndex = lastSessionIdMatch !== -1 ? lastSessionIdMatch : output.indexOf('{');
          const endIndex = output.lastIndexOf('}');

          if (startIndex !== -1 && endIndex !== -1 && endIndex > startIndex) {
            const cleanJsonStr = output.substring(startIndex, endIndex + 1);            try {
              const parsed = JSON.parse(cleanJsonStr);
              
              if (parsed.response) {
                finalResponse = parsed.response;
              } else if (parsed.error) {
                finalResponse = `API Error: ${parsed.error.message || JSON.stringify(parsed.error)}`;
              }

              if (parsed.stats && parsed.stats.models) {
                let totalTokens = 0;
                for (const modelKey of Object.keys(parsed.stats.models)) {
                  const tokens = parsed.stats.models[modelKey]?.tokens?.total || 0;
                  totalTokens += tokens;
                }
                usage.total_tokens = totalTokens;
              }
            } catch (e) {
              logger.warn('Failed to parse Gemini JSON output for telemetry', e.message);
              if (finalResponse.length > 1500) {
                finalResponse = '... ' + finalResponse.substring(finalResponse.length - 1500);
              }
            }
          } else {
             if (finalResponse.length > 1500) {
                finalResponse = '... ' + finalResponse.substring(finalResponse.length - 1500);
             }
          }
        }

        this._logTelemetry(routine.name, usage, logFile);

        logStream.end(() => {
          resolve({
            success: code === 0,
            code,
            output: finalResponse,
            usage,
            logFile,
            timedOut: code === null
          });
        });
      });

      
      child.on('error', (err) => {
        if (taskId) this._removeActiveTask(taskId);
        clearTimeout(timer);

        logger.error(`Failed to start routine ${routine.name}`, err);
        logStream.write(`\n[SPAWN_ERROR] ${err.message}`);
        logStream.end();
        resolve({ success: false, error: err.message, logFile });
      });
    });
  }

  async _runSetupScript(script) {
    return new Promise((resolve, reject) => {
      const isPython = script.endsWith('.py');
      const cmd = isPython ? 'python3' : 'bash';
      const args = isPython ? [script] : ['-c', script];
      
      const child = spawn(cmd, args, { cwd: path.resolve('..') });
      let output = '';
      let error = '';

      child.stdout.on('data', (data) => output += data);
      child.stderr.on('data', (data) => error += data);

      child.on('close', (code) => {
        if (code === 0) resolve(output.trim());
        else reject(new Error(error || `Exited with code ${code}`));
      });

      child.on('error', (err) => reject(err));
      setTimeout(() => child.kill('SIGKILL'), 30000); 
    });
  }


  _addActiveTask(taskId, routineName, logFile, pid) {
    const activeTasksFile = path.join(this.logsDir, 'active_tasks.json');
    let data = {};
    try {
      if (!fs.existsSync(this.logsDir)) fs.mkdirSync(this.logsDir, { recursive: true });
      if (fs.existsSync(activeTasksFile)) {
        data = JSON.parse(fs.readFileSync(activeTasksFile, 'utf-8') || '{}');
      }
      data[taskId] = { routine: routineName, start_time: new Date().toISOString(), log_file: logFile, pid };
      fs.writeFileSync(activeTasksFile, JSON.stringify(data, null, 2));
    } catch (e) {
      logger.error('Failed to update active_tasks.json', e);
    }
  }

  _removeActiveTask(taskId) {
    const activeTasksFile = path.join(this.logsDir, 'active_tasks.json');
    let data = {};
    try {
      if (fs.existsSync(activeTasksFile)) {
        data = JSON.parse(fs.readFileSync(activeTasksFile, 'utf-8') || '{}');
        delete data[taskId];
        fs.writeFileSync(activeTasksFile, JSON.stringify(data, null, 2));
      }
    } catch (e) {
      logger.error('Failed to update active_tasks.json', e);
    }
  }

  _logTelemetry(routineName, usage, logFile) {
    const telemetryFile = path.join(this.logsDir, 'telemetry.json');
    let data = [];
    try {
      if (!fs.existsSync(this.logsDir)) fs.mkdirSync(this.logsDir, { recursive: true });
      if (fs.existsSync(telemetryFile)) {
        data = JSON.parse(fs.readFileSync(telemetryFile, 'utf-8') || '[]');
      }
      data.push({ routine: routineName, timestamp: new Date().toISOString(), total_tokens: usage.total_tokens, log_file: logFile });
      if (data.length > 100) data.shift();
      fs.writeFileSync(telemetryFile, JSON.stringify(data, null, 2));
    } catch (e) {
      logger.error('Failed to write telemetry.json', e);
    }
  }
}

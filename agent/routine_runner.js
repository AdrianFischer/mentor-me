import { spawn } from 'child_process';
import fs from 'fs';
import path from 'path';
import { logger } from './logger.js';

export class RoutineRunner {
  constructor(config = {}) {
    this.logsDir = config.logsDir || path.resolve('logs/routines');
    this.geminiPath = config.geminiPath || 'gemini'; // Default to global gemini cli
  }

  /**
   * Runs a routine in a detached subprocess.
   */
  async run(routine) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const logFile = path.join(this.logsDir, `${routine.name.replace(/\s+/g, '_')}_${timestamp}.log`);
    const timeout = (routine.timeout || 300) * 1000; // Default 5 mins

    logger.info(`Starting routine execution: ${routine.name}. Timeout: ${routine.timeout}s`);
    
    return new Promise((resolve) => {
      const logStream = fs.createWriteStream(logFile);
      
      // Construct command arguments
      let args = [];
      if (this.geminiPath.includes('gemini')) {
        args = [
          '-m', routine.task,
          '--context', routine.context || '',
          '--json' // Use JSON mode to get metadata easily
        ];
      } else {
        // Fallback for test mocks or generic commands
        args = [routine.task];
        if (routine.context) args.push(routine.context);
      }

      const child = spawn(this.geminiPath, args, {
        detached: true,
        stdio: ['ignore', 'pipe', 'pipe']
      });

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
        logger.warn(`Routine ${routine.name} timed out after ${routine.timeout}s. Killing...`);
        child.kill('SIGKILL');
        logStream.write('\n[TIMEOUT_ERROR] Process killed by Watchdog due to timeout.');
      }, timeout);

      child.on('close', (code) => {
        clearTimeout(timer);
        logStream.end();
        
        logger.info(`Routine ${routine.name} finished with code ${code}`);

        let usage = { total_tokens: 0 };
        let finalResponse = output.trim();

        // Try to parse JSON output if we used --json
        if (this.geminiPath.includes('gemini') && output.trim()) {
          try {
            // Gemini CLI returns JSON lines or a single JSON block. 
            // We assume it's a single block for simplicity or take the last line if multiple.
            const lines = output.trim().split('\n');
            const lastLine = lines[lines.length - 1];
            const parsed = JSON.parse(lastLine);
            
            // Map Gemini CLI metadata to our usage format
            // Gemini CLI typically returns a response object with metadata
            usage.total_tokens = parsed.usage_metadata?.total_token_count || 0;
            
            // Extract text from candidates
            if (parsed.candidates?.[0]?.content?.parts?.[0]?.text) {
              finalResponse = parsed.candidates[0].content.parts[0].text;
            }
          } catch (e) {
            logger.warn('Failed to parse Gemini JSON output for telemetry', e.message);
          }
        }

        this._logTelemetry(routine.name, usage);
        
        resolve({
          success: code === 0,
          output: finalResponse,
          usage,
          logFile,
          timedOut: code === null // SIGKILL results in null code
        });
      });

      child.on('error', (err) => {
        clearTimeout(timer);
        logger.error(`Failed to start routine ${routine.name}`, err);
        logStream.write(`\n[SPAWN_ERROR] ${err.message}`);
        logStream.end();
        resolve({ success: false, error: err.message, logFile });
      });
    });
  }

  _logTelemetry(routineName, usage) {
    const telemetryFile = path.join(this.logsDir, 'telemetry.json');
    let data = [];
    
    try {
      // Ensure logsDir exists
      if (!fs.existsSync(this.logsDir)) {
        fs.mkdirSync(this.logsDir, { recursive: true });
      }

      if (fs.existsSync(telemetryFile)) {
        const content = fs.readFileSync(telemetryFile, 'utf-8');
        data = JSON.parse(content || '[]');
      }
      
      data.push({
        routine: routineName,
        timestamp: new Date().toISOString(),
        total_tokens: usage.total_tokens
      });

      // Keep only last 100 entries to prevent bloat
      if (data.length > 100) data.shift();

      fs.writeFileSync(telemetryFile, JSON.stringify(data, null, 2));
    } catch (e) {
      logger.error('Failed to write telemetry.json', e);
    }
  }
}

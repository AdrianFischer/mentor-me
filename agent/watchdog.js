import fs from 'fs';
import path from 'path';
import { logger } from './logger.js';
import { RoutineRunner } from './routine_runner.js';

/**
 * Watchdog is responsible for proactively running scheduled routines.
 * It scans a directory for routine definitions and executes them if their interval has passed.
 */
export class Watchdog {
  constructor(config = {}) {
    this.routinesDir = config.routinesDir || path.resolve('../data/routines');
    this.logsDir = config.logsDir || path.resolve('../logs/routines');
    this.intervalMs = config.intervalMs || 1000;
    this.routinesState = new Map(); // Store last_execution_time for each routine
    this.timer = null;
    this.onWorkAccomplished = config.onWorkAccomplished || (() => {});
    
    // Initialize the runner
    this.runner = new RoutineRunner({ 
      logsDir: this.logsDir,
      geminiPath: config.geminiPath || 'gemini'
    });

    // Ensure directories exist
    if (!fs.existsSync(this.routinesDir)) fs.mkdirSync(this.routinesDir, { recursive: true });
    if (!fs.existsSync(this.logsDir)) fs.mkdirSync(this.logsDir, { recursive: true });
  }

  /**
   * Starts the watchdog loop.
   */
  start() {
    if (this.timer) return;
    logger.info(`Watchdog started. Monitoring: ${this.routinesDir}`);
    this.timer = setInterval(() => this.tick(), this.intervalMs);
  }

  /**
   * Stops the watchdog loop.
   */
  stop() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
      logger.info('Watchdog stopped.');
    }
  }

  /**
   * Single tick logic: scan routines and trigger if due.
   */
  async tick() {
    try {
      const files = fs.readdirSync(this.routinesDir).filter(f => f.endsWith('.yaml') || f.endsWith('.json'));
      const now = Date.now();

      for (const file of files) {
        await this._checkRoutine(file, now);
      }
    } catch (error) {
      logger.error('Watchdog Tick Error', error);
    }
  }

  async _checkRoutine(file, now) {
    const routinePath = path.join(this.routinesDir, file);
    
    try {
      const content = fs.readFileSync(routinePath, 'utf-8');
      const routine = JSON.parse(content);
      
      const lastExecution = this.routinesState.get(file) || routine.last_executed_at || 0;
      const intervalMs = (routine.execute_every_seconds || 60) * 1000;

      if (now >= lastExecution + intervalMs) {
        logger.info(`Triggering routine: ${routine.name} (${file})`);
        
        // Update state BEFORE calling to avoid double triggers if logic is slow
        this.routinesState.set(file, now);
        
        // Persist last execution time in the file
        routine.last_executed_at = now;
        fs.writeFileSync(routinePath, JSON.stringify(routine, null, 2), 'utf-8');
        
        // Execute the routine independently
        this.runner.run(routine).then(result => {
          this._handleResult(routine, result);
        }).catch(err => {
          logger.error(`Routine execution failed for ${routine.name}`, err);
        });
      }
    } catch (error) {
      logger.error(`Error processing routine file ${file}`, error);
    }
  }

  _handleResult(routine, result) {
    if (result.timedOut) {
      this.onWorkAccomplished(`⚠️ <b>Routine Timeout</b>: "${routine.name}" took too long and was terminated.`);
      return;
    }

    if (!result.success) {
      logger.warn(`Routine "${routine.name}" failed with code ${result.code}: ${result.error || 'Check logs'}`);
      
      let errorContext = result.error ? `\n\n<i>${result.error}</i>` : '';
      if (result.output && !result.error) {
         // sanitize HTML for Telegram
         const safeOutput = result.output.replace(/</g, '&lt;').replace(/>/g, '&gt;').substring(0, 400);
         errorContext = `\n\n<b>Last Output:</b>\n<pre>${safeOutput}</pre>`;
      }

      this.onWorkAccomplished(`🚨 <b>Routine Failed</b>: "${routine.name}" encountered an error (Code: ${result.code}).${errorContext}`);
      return;
    }

    const output = result.output || '';
    
    // "Meaningful Work" Filter: Skip if output is 'NO_ACTION_TAKEN'
    if (output.includes('NO_ACTION_TAKEN')) {
      logger.info(`Routine "${routine.name}" finished with no action taken.`);
      return;
    }

    // Otherwise, notify user of work done
    // sanitize output to ensure Telegram HTML parse mode doesn't break
    const safeOutput = output.replace(/</g, '&lt;').replace(/>/g, '&gt;');
    const message = `🤖 <b>Routine Report</b>: "${routine.name}"\n\n${safeOutput}\n\n<i>Tokens used: ${result.usage?.total_tokens || 0}</i>`;
    this.onWorkAccomplished(message);
  }
}

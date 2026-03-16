import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { Watchdog } from '../watchdog.js';
import fs from 'fs';
import path from 'path';
import { spawn } from 'child_process';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

describe('Test 10: Watchdog Routine Timeout Enforcement Test', () => {
  const testRoutinesDir = path.resolve(__dirname, 'tmp_routines_t10');
  const testLogsDir = path.resolve(__dirname, 'tmp_logs_t10');

  beforeEach(() => {
    if (!fs.existsSync(testRoutinesDir)) fs.mkdirSync(testRoutinesDir, { recursive: true });
    if (!fs.existsSync(testLogsDir)) fs.mkdirSync(testLogsDir, { recursive: true });
  });

  afterEach(() => {
    if (fs.existsSync(testRoutinesDir)) fs.rmSync(testRoutinesDir, { recursive: true, force: true });
    if (fs.existsSync(testLogsDir)) fs.rmSync(testLogsDir, { recursive: true, force: true });
    vi.restoreAllMocks();
  });

  it('AC 10.1: Watchdog forcefully terminates routine that exceeds strict timeout', async () => {
    const watchdog = new Watchdog({
      routinesDir: testRoutinesDir,
      logsDir: testLogsDir,
      geminiPath: 'bash' // We will run a bash script that sleeps
    });

    const timeoutSeconds = 2; // 2 seconds timeout for test speed
    
    // We will spawn a process that sleeps for 10 seconds.
    // We expect the routine to be terminated gracefully within 2 seconds.
    const routine = {
      name: 'Hanging Routine',
      timeout: timeoutSeconds,
      task: '-c',
      context: 'sleep 10' 
    };

    const startTime = Date.now();
    const result = await watchdog.runner.run(routine);
    const endTime = Date.now();

    const durationMs = endTime - startTime;

    // Wait, routine_runner's fallback args:
    // args = [routine.task];
    // if (routine.context) args.push(routine.context);
    // So for bash, args = ['-c', 'sleep 10']. This works.

    // Expect it to return timedOut = true or similar, wait let's check routine_runner.js
    // routine_runner returns { success: code === 0, timedOut: code === null, output, etc. }
    // Wait, if it's killed by SIGTERM, code is usually null.

    expect(result.timedOut).toBe(true);
    expect(result.success).toBe(false);
    
    // Check if duration is close to timeout (e.g. 2000ms + some buffer)
    expect(durationMs).toBeGreaterThanOrEqual(1900);
    expect(durationMs).toBeLessThan(4000); // Should definitely be less than 10 seconds

    // Check if the log file contains the timeout error message
    const logFileContent = fs.readFileSync(result.logFile, 'utf-8');
    expect(logFileContent).toContain('[TIMEOUT_ERROR] Process signaled by Watchdog (SIGTERM) due to timeout');
  }, 10000); // 10s test timeout to be safe
});

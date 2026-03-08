import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { RoutineRunner } from '../routine_runner.js';
import fs from 'fs';
import path from 'path';

describe('RoutineRunner Integration', () => {
  const baseTestLogsDir = path.resolve('agent/test/tmp_logs_runner');

  beforeEach(() => {
    if (!fs.existsSync(baseTestLogsDir)) fs.mkdirSync(baseTestLogsDir, { recursive: true });
  });

  afterEach(() => {
    // We can cleanup at the end of the suite
  });

  it('AC 2: Should execute a routine using a subprocess', async () => {
    const testLogsDir = path.join(baseTestLogsDir, 'test_ac2');
    if (!fs.existsSync(testLogsDir)) fs.mkdirSync(testLogsDir, { recursive: true });

    const runner = new RoutineRunner({ 
      logsDir: testLogsDir,
      geminiPath: 'echo' 
    });
    
    const routine = {
      name: 'Test Routine',
      task: 'Success Message',
      context: 'Some Context',
      timeout: 5
    };

    const result = await runner.run(routine);
    
    expect(result.success).toBe(true);
    expect(result.output).toBe('Success Message Some Context');
    expect(fs.existsSync(result.logFile)).toBe(true);
    const logContent = fs.readFileSync(result.logFile, 'utf-8');
    expect(logContent).toContain('Success Message Some Context');
  });

  it('AC 3: Should forcibly kill a routine after timeout', async () => {
    const testLogsDir = path.join(baseTestLogsDir, 'test_ac3');
    if (!fs.existsSync(testLogsDir)) fs.mkdirSync(testLogsDir, { recursive: true });

    const runner = new RoutineRunner({ 
      logsDir: testLogsDir,
      geminiPath: 'sleep' 
    });
    
    const routine = {
      name: 'Sleepy Routine',
      task: '10', 
      timeout: 1  
    };

    const startTime = Date.now();
    const result = await runner.run(routine);
    const endTime = Date.now();

    expect(result.timedOut).toBe(true);
    expect(result.success).toBe(false);
    expect(endTime - startTime).toBeLessThan(5000); 
    
    expect(fs.existsSync(result.logFile)).toBe(true);
    const logContent = fs.readFileSync(result.logFile, 'utf-8');
    expect(logContent).toContain('[TIMEOUT_ERROR]');
  });
});

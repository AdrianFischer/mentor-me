import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { Watchdog } from '../watchdog.js';
import fs from 'fs';
import path from 'path';

describe('Watchdog Trigger & Discovery Logic', () => {
  const testRoutinesDir = path.resolve('agent/test/tmp_routines');
  const testLogsDir = path.resolve('agent/test/tmp_logs');

  beforeEach(() => {
    if (!fs.existsSync(testRoutinesDir)) fs.mkdirSync(testRoutinesDir, { recursive: true });
    if (!fs.existsSync(testLogsDir)) fs.mkdirSync(testLogsDir, { recursive: true });
    vi.useFakeTimers();
  });

  afterEach(() => {
    fs.rmSync(testRoutinesDir, { recursive: true, force: true });
    fs.rmSync(testLogsDir, { recursive: true, force: true });
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  it('AC 1: Tick every 1000ms and discover new routine files', async () => {
    const onWork = vi.fn();
    const watchdog = new Watchdog({
      routinesDir: testRoutinesDir,
      logsDir: testLogsDir,
      intervalMs: 1000,
      onWorkAccomplished: onWork,
      geminiPath: 'echo' // Mock runner to just echo
    });

    // Mock the runner.run to return a controlled result
    vi.spyOn(watchdog.runner, 'run').mockResolvedValue({
      success: true,
      output: 'Meaningful work done',
      usage: { total_tokens: 100 }
    });

    watchdog.start();
    
    // Create a routine file
    const routineFile = path.join(testRoutinesDir, 'test_routine.json');
    fs.writeFileSync(routineFile, JSON.stringify({
      name: 'Test Routine',
      execute_every_seconds: 5,
      task: 'say hello'
    }));

    // Advance 1s - initial discovery
    await vi.advanceTimersByTimeAsync(1000);
    
    // We need to wait for the promise from runner.run to resolve
    // Since it's an async then() in watchdog.js
    await vi.runAllTicks(); 
    
    expect(watchdog.runner.run).toHaveBeenCalledTimes(1);
    expect(onWork).toHaveBeenCalledWith(expect.stringContaining('Meaningful work done'));

    // Advance 4 more seconds - total 5s - should not trigger yet
    await vi.advanceTimersByTimeAsync(4000);
    expect(watchdog.runner.run).toHaveBeenCalledTimes(1);

    // Advance 1 more second - total 6s - should trigger again
    await vi.advanceTimersByTimeAsync(1000);
    await vi.runAllTicks();
    expect(watchdog.runner.run).toHaveBeenCalledTimes(2);

    watchdog.stop();
  });

  it('should skip Telegram if output is NO_ACTION_TAKEN', async () => {
    const onWork = vi.fn();
    const watchdog = new Watchdog({
      routinesDir: testRoutinesDir,
      logsDir: testLogsDir,
      onWorkAccomplished: onWork,
      geminiPath: 'echo'
    });

    vi.spyOn(watchdog.runner, 'run').mockResolvedValue({
      success: true,
      output: 'NO_ACTION_TAKEN',
      usage: { total_tokens: 10 }
    });

    const routineFile = path.join(testRoutinesDir, 'idle_routine.json');
    fs.writeFileSync(routineFile, JSON.stringify({
      name: 'Idle Routine',
      execute_every_seconds: 1,
      task: 'check'
    }));

    await watchdog.tick();
    await vi.runAllTicks();

    expect(watchdog.runner.run).toHaveBeenCalled();
    expect(onWork).not.toHaveBeenCalled();
  });
});

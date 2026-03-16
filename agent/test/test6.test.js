import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { RoutinesManager } from '../routines_manager.js';
import fs from 'fs';
import path from 'path';

describe('Test 6: Large Log File Seeking Performance Test', () => {
  const testLogsDir = path.resolve('test/tmp_logs_test6');
  let manager;

  beforeEach(() => {
    if (!fs.existsSync(testLogsDir)) fs.mkdirSync(testLogsDir, { recursive: true });
    manager = new RoutinesManager('dummy_routines', testLogsDir);
  });

  afterEach(() => {
    fs.rmSync(testLogsDir, { recursive: true, force: true });
    vi.restoreAllMocks();
  });

  it('AC 6: get_active_tasks_and_logs reads large logs efficiently using openSync and readSync', async () => {
    const largeLogFile = path.join(testLogsDir, 'large.log');
    
    // Create a 15MB dummy file
    const mb = 1024 * 1024;
    const buf = Buffer.alloc(15 * mb, 'A');
    // Last 50 bytes is 'B'
    buf.fill('B', 15 * mb - 50);
    fs.writeFileSync(largeLogFile, buf);

    // active tasks json
    fs.writeFileSync(path.join(testLogsDir, 'active_tasks.json'), JSON.stringify({
      "task1": { routine: "my_routine", start_time: "2023-01-01T00:00:00Z", log_file: largeLogFile }
    }));

    const readFileSyncSpy = vi.spyOn(fs, 'readFileSync');
    const openSyncSpy = vi.spyOn(fs, 'openSync');
    const readSyncSpy = vi.spyOn(fs, 'readSync');

    const result = await manager.executeTool({ name: 'get_active_tasks_and_logs', args: {} });

    expect(result.result).toBe('success');
    expect(result.active_tasks).toHaveLength(1);
    expect(result.active_tasks[0].log_tail).toContain('BBBBBBBBBBBBBBBBBBBB');
    expect(result.active_tasks[0].log_tail.length).toBeLessThanOrEqual(2003); // 2000 + '...'

    // readFileSync should be called for active_tasks.json, but NOT for large.log
    const logFileReads = readFileSyncSpy.mock.calls.filter(call => call[0] === largeLogFile);
    expect(logFileReads).toHaveLength(0);

    // openSync and readSync should be called for large.log
    const logFileOpens = openSyncSpy.mock.calls.filter(call => call[0] === largeLogFile);
    expect(logFileOpens.length).toBeGreaterThan(0);
    expect(readSyncSpy).toHaveBeenCalled();
  });
});

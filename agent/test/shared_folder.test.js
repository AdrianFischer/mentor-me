import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { SharedFolderManager } from '../shared_folder_manager.js';
import fs from 'fs';
import path from 'path';

describe('Test 3: Shared Folder Sandbox Security Test', () => {
  const testSharedDir = path.resolve('agent/test/tmp_shared_sandbox');

  beforeEach(() => {
    if (!fs.existsSync(testSharedDir)) {
      fs.mkdirSync(testSharedDir, { recursive: true });
    }
  });

  afterEach(() => {
    if (fs.existsSync(testSharedDir)) {
      fs.rmSync(testSharedDir, { recursive: true, force: true });
    }
  });

  it('rejects execution if the command attempts to traverse outside the shared directory', async () => {
    const manager = new SharedFolderManager(testSharedDir);
    
    // Test 1: Using ../
    const res1 = manager.executeTool({ name: 'run_shared_command', args: { command: 'cat ../secret.txt' } });
    // Note: executeTool is async? No, it's async but it just returns the Promise in actual use. Wait, executeTool is async in the class.
    // Let's await it.
    const awaitedRes1 = await res1;
    expect(awaitedRes1.result).toBe('error');
    expect(awaitedRes1.message).toContain('traverse outside');

    // Test 2: Using absolute path
    const res2 = await manager.executeTool({ name: 'run_shared_command', args: { command: '/bin/bash -c "echo hi"' } });
    expect(res2.result).toBe('error');
    expect(res2.message).toContain('traverse outside');
    
    // Test 3: Valid command inside
    const res3 = await manager.executeTool({ name: 'run_shared_command', args: { command: 'echo "hello"' } });
    expect(res3.result).toBe('success');
    expect(res3.output).toBe('hello');
  });
});

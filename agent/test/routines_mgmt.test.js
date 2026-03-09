import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { RoutinesManager } from '../routines_manager.js';
import fs from 'fs';
import path from 'path';

describe('RoutinesManager Routine Management', () => {
  const testRoutinesDir = path.resolve('agent/test/tmp_routines_mgmt');
  let manager;

  beforeEach(() => {
    if (!fs.existsSync(testRoutinesDir)) fs.mkdirSync(testRoutinesDir, { recursive: true });
    
    manager = new RoutinesManager(testRoutinesDir);
  });

  afterEach(() => {
    fs.rmSync(testRoutinesDir, { recursive: true, force: true });
  });

  it('should list routines', async () => {
    fs.writeFileSync(path.join(testRoutinesDir, 'test.json'), JSON.stringify({ name: 'Test' }));
    const result = await manager.executeTool({ name: 'list_routines', args: {} });
    expect(result.result).toBe('success');
    expect(result.routines).toHaveLength(1);
    expect(result.routines[0].name).toBe('Test');
    expect(result.routines[0].filename).toBe('test.json');
  });

  it('should update (create) a routine', async () => {
    const args = {
      filename: 'new_routine.json',
      name: 'New Routine',
      execute_every_seconds: 60,
      task: 'do something'
    };
    const result = await manager.executeTool({ name: 'update_routine', args });
    expect(result.result).toBe('success');
    expect(fs.existsSync(path.join(testRoutinesDir, 'new_routine.json'))).toBe(true);
    
    const content = JSON.parse(fs.readFileSync(path.join(testRoutinesDir, 'new_routine.json'), 'utf-8'));
    expect(content.name).toBe('New Routine');
    expect(content.filename).toBeUndefined(); // Filename should not be inside
  });

  it('should delete a routine', async () => {
    fs.writeFileSync(path.join(testRoutinesDir, 'to_delete.json'), JSON.stringify({ name: 'Delete me' }));
    const result = await manager.executeTool({ name: 'delete_routine', args: { filename: 'to_delete.json' } });
    expect(result.result).toBe('success');
    expect(fs.existsSync(path.join(testRoutinesDir, 'to_delete.json'))).toBe(false);
  });
});

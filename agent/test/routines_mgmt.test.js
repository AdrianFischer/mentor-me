import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { AgentBrain } from '../agent.js';
import fs from 'fs';
import path from 'path';

describe('AgentBrain Routine Management', () => {
  const testRoutinesDir = path.resolve('agent/test/tmp_routines_mgmt');
  let brain;

  beforeEach(() => {
    if (!fs.existsSync(testRoutinesDir)) fs.mkdirSync(testRoutinesDir, { recursive: true });
    
    // Mock services
    const mcp = { discoverTools: vi.fn().mockResolvedValue([]), callTool: vi.fn() };
    const gemini = { process: vi.fn(), processToolResult: vi.fn() };
    
    brain = new AgentBrain({ mcp, gemini });
    brain.routinesDir = testRoutinesDir; // Override for testing
  });

  afterEach(() => {
    fs.rmSync(testRoutinesDir, { recursive: true, force: true });
  });

  it('should list routines', () => {
    fs.writeFileSync(path.join(testRoutinesDir, 'test.json'), JSON.stringify({ name: 'Test' }));
    const result = brain._listRoutines();
    expect(result.result).toBe('success');
    expect(result.routines).toHaveLength(1);
    expect(result.routines[0].name).toBe('Test');
    expect(result.routines[0].filename).toBe('test.json');
  });

  it('should update (create) a routine', () => {
    const args = {
      filename: 'new_routine.json',
      name: 'New Routine',
      execute_every_seconds: 60,
      task: 'do something'
    };
    const result = brain._updateRoutine(args);
    expect(result.result).toBe('success');
    expect(fs.existsSync(path.join(testRoutinesDir, 'new_routine.json'))).toBe(true);
    
    const content = JSON.parse(fs.readFileSync(path.join(testRoutinesDir, 'new_routine.json'), 'utf-8'));
    expect(content.name).toBe('New Routine');
    expect(content.filename).toBeUndefined(); // Filename should not be inside
  });

  it('should delete a routine', () => {
    fs.writeFileSync(path.join(testRoutinesDir, 'to_delete.json'), JSON.stringify({ name: 'Delete me' }));
    const result = brain._deleteRoutine({ filename: 'to_delete.json' });
    expect(result.result).toBe('success');
    expect(fs.existsSync(path.join(testRoutinesDir, 'to_delete.json'))).toBe(false);
  });
});

import { describe, it, expect, vi } from 'vitest';
import { AgentBrain } from '../agent.js';

describe('Test 7: Verification-First Mutation Workflow Test', () => {
  it('AC 7: AgentBrain enforces an internal Get check to validate data change before returning success', async () => {
    const mockMcp = { discoverTools: vi.fn().mockResolvedValue([]), callTool: vi.fn() };
    const mockTaskTools = { 
        getTools: () => [{name: 'add_task'}], 
        executeTool: vi.fn().mockResolvedValue({ result: 'success', data: { id: 'new-id' } }) 
    };
    const mockGemini = { 
      process: vi.fn().mockResolvedValue({ text: '', toolCalls: [{ name: 'add_task', args: { title: 'Test Task' } }] }),
      processToolResult: vi.fn().mockResolvedValue({ text: 'Task created successfully.', toolCalls: [] })
    };

    const brain = new AgentBrain({ mcp: mockMcp, gemini: mockGemini, taskTools: mockTaskTools });
    
    const executeSpy = vi.spyOn(brain, '_executeTool');

    await brain.process('Create a task called Test Task');

    const calls = executeSpy.mock.calls.map(c => c[0].name);
    
    expect(calls).toContain('add_task');
    // We expect some verification tool to be called after add_task
    const addTaskIndex = calls.indexOf('add_task');
    const verifyTools = ['verify_task_exists', 'get_task', 'list_todos_by_status', 'verify_routine_active'];
    const verifyIndex = calls.findIndex(name => verifyTools.includes(name));
    
    expect(verifyIndex).toBeGreaterThan(addTaskIndex);
  });
});

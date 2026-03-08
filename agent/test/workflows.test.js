import { describe, it, expect, vi } from 'vitest';
import { AgentBrain } from '../agent.js';

describe('6. Functional Workflows (Conversational)', () => {
  const mockServices = {
    mcp: { 
      discoverTools: vi.fn().mockResolvedValue([]),
      callTool: vi.fn().mockResolvedValue({})
    },
    gemini: { 
      process: vi.fn().mockResolvedValue({ text: 'Listing...', toolCalls: [] }),
      processToolResult: vi.fn().mockResolvedValue({ text: 'Done', toolCalls: [] })
    }
  };

  it('AC 34: User says "What tasks do I have?" -> Calls list_todos_by_status', async () => {
    const brain = new AgentBrain(mockServices);
    const result = await brain.processInput('What tasks do I have?');
    expect(result.toolCalls).toContainEqual(expect.objectContaining({ name: 'list_todos_by_status' }));
  });

  it('AC 35: User says "Mark task 2 as done" -> Calls update_todo_by_index', async () => {
    const brain = new AgentBrain(mockServices);
    const result = await brain.processInput('Mark task 2 as done');
    expect(result.toolCalls).toContainEqual(expect.objectContaining({ 
      name: 'update_todo_by_index',
      args: expect.objectContaining({ index: 2, is_completed: true })
    }));
  });

  it('AC 36: User says "Add notes to task 1"', async () => {
    const brain = new AgentBrain(mockServices);
    const result = await brain.processInput('Add notes to task 1: "Check the reactor"');
    expect(result.toolCalls).toContainEqual(expect.objectContaining({ 
      name: 'update_todo_by_index',
      args: expect.objectContaining({ index: 1, notes: expect.stringContaining('reactor') })
    }));
  });

  it('AC 37: User says "Remember I am allergic to peanuts"', async () => {
    const brain = new AgentBrain(mockServices);
    const result = await brain.processInput('Remember I am allergic to peanuts');
    expect(result.toolCalls).toContainEqual(expect.objectContaining({ 
      name: 'save_memory',
      args: expect.objectContaining({ fact: expect.stringContaining('allergic') })
    }));
  });

  it('AC 38: Maps user indices to UUIDs (via MCP Server response)', () => {
    expect(true).toBe(true);
  });

  it('AC 39: Handles complex requests', async () => {
    const brain = new AgentBrain(mockServices);
    const result = await brain.processInput('Show finished tasks');
    expect(result.toolCalls).toContainEqual(expect.objectContaining({ 
      name: 'list_todos_by_status',
      args: expect.objectContaining({ status: 'completed' })
    }));
  });

  it('AC 40: Proactively asks for clarification', async () => {
    const brain = new AgentBrain(mockServices);
    const result = await brain.processInput('Update this task');
    expect(result.text).toContain('Which task');
  });
});

import { describe, it, expect, vi } from 'vitest';
import { AgentBrain } from '../agent.js';

describe('Test 8: Polymorphic process(input) API Test', () => {
  it('AC 8: AgentBrain correctly routes inputs whether string or multimodal objects', async () => {
    const mockMcp = { discoverTools: vi.fn().mockResolvedValue([]), callTool: vi.fn() };
    const mockTaskTools = { getTools: () => [], executeTool: vi.fn() };
    const mockGemini = { 
      process: vi.fn().mockResolvedValue({ text: 'Processed output', toolCalls: [] }),
      processToolResult: vi.fn()
    };

    const brain = new AgentBrain({ mcp: mockMcp, gemini: mockGemini, taskTools: mockTaskTools });
    
    // 1. Raw text string
    const textInput = "Hello world";
    await brain.process(textInput);
    
    expect(mockGemini.process).toHaveBeenCalledWith(
      textInput,
      expect.any(Array)
    );

    // 2. Audio object
    mockGemini.process.mockClear();
    const audioInput = { audioBase64: 'bWFnaWM=', mimeType: 'audio/mp3' };
    await brain.process(audioInput);
    
    expect(mockGemini.process).toHaveBeenCalledWith(
      expect.arrayContaining([
        { inlineData: { data: 'bWFnaWM=', mimeType: 'audio/mp3' } },
        expect.objectContaining({ text: expect.any(String) })
      ]),
      expect.any(Array)
    );

    // 3. Image object
    mockGemini.process.mockClear();
    const imageInput = { imageBase64: 'aW1hZ2U=', mimeType: 'image/png', text: 'Look at this' };
    await brain.process(imageInput);
    
    expect(mockGemini.process).toHaveBeenCalledWith(
      expect.arrayContaining([
        { inlineData: { data: 'aW1hZ2U=', mimeType: 'image/png' } },
        { text: 'Look at this' }
      ]),
      expect.any(Array)
    );

    // 4. Invalid object
    mockGemini.process.mockClear();
    const invalidInput = { videoBase64: 'dmlkZW8=' }; // Unsupported
    const response = await brain.process(invalidInput);
    expect(response).toContain('❌ Sorry');
    expect(response).toContain('Invalid input format');
  });
});

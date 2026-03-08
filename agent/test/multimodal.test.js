import { describe, it, expect, vi, beforeEach } from 'vitest';
import { GeminiService } from '../gemini.js';
import { AgentBrain } from '../agent.js';

describe('Multimodal Voice Processing', () => {
  let gemini;
  let mockMcp;
  let brain;

  beforeEach(() => {
    gemini = new GeminiService({ geminiApiKey: 'test_key' });
    mockMcp = {
      discoverTools: vi.fn().mockResolvedValue([]),
      callTool: vi.fn().mockResolvedValue({ success: true })
    };
    brain = new AgentBrain({ mcp: mockMcp, gemini });
  });

  describe('GeminiService Multimodal Support', () => {
    it('should accept a multimodal array as a prompt', async () => {
      const prompt = [
        { inlineData: { data: 'base64audio', mimeType: 'audio/ogg' } },
        { text: 'What did I say?' }
      ];

      // Mock the genAI SDK parts
      const mockSendMessage = vi.fn().mockResolvedValue({
        response: {
          candidates: [{
            content: { parts: [{ text: 'I heard you!' }] }
          }]
        }
      });
      const mockStartChat = vi.fn().mockReturnValue({
        sendMessage: mockSendMessage,
        getHistory: vi.fn().mockResolvedValue([
          { role: 'user', parts: prompt }
        ])
      });
      const mockGetGenerativeModel = vi.fn().mockReturnValue({
        startChat: mockStartChat
      });
      
      gemini.genAI.getGenerativeModel = mockGetGenerativeModel;

      const result = await gemini.process(prompt);
      
      expect(mockSendMessage).toHaveBeenCalledWith(prompt);
      expect(result.text).toBe('I heard you!');
      
      // Verify history is cleaned
      expect(gemini.history[0].parts).not.toContainEqual(expect.objectContaining({ inlineData: expect.any(Object) }));
      expect(gemini.history[0].parts).toContainEqual({ text: '[Processed Voice Memo]' });
    });

    it('should still support string prompts', async () => {
       const mockSendMessage = vi.fn().mockResolvedValue({
        response: {
          candidates: [{
            content: { parts: [{ text: 'Hello!' }] }
          }]
        }
      });
      const mockStartChat = vi.fn().mockReturnValue({
        sendMessage: mockSendMessage,
        getHistory: vi.fn().mockResolvedValue([])
      });
      gemini.genAI.getGenerativeModel = vi.fn().mockReturnValue({
        startChat: mockStartChat
      });

      const result = await gemini.process('Hi');
      expect(mockSendMessage).toHaveBeenCalledWith('Hi');
      expect(result.text).toBe('Hello!');
    });
  });

  describe('AgentBrain Multimodal Integration', () => {
    it('should have a process method that handles audio input objects', async () => {
      // Mock gemini.process to return a tool call
      vi.spyOn(gemini, 'process').mockResolvedValueOnce({
        text: '',
        toolCalls: [{ name: 'add_task', args: { title: 'Buy milk' } }]
      });
      vi.spyOn(gemini, 'processToolResult').mockResolvedValueOnce({
        text: 'Added task: Buy milk',
        toolCalls: []
      });

      const audioBase64 = 'someBase64AudioData';
      const mimeType = 'audio/ogg';

      const response = await brain.process({ audioBase64, mimeType });

      expect(gemini.process).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.objectContaining({ inlineData: { data: audioBase64, mimeType } }),
          expect.objectContaining({ text: expect.any(String) })
        ]),
        expect.any(Array)
      );
      expect(mockMcp.callTool).toHaveBeenCalledWith('add_task', { title: 'Buy milk' });
      expect(response).toBe('Added task: Buy milk');
    });
  });
});

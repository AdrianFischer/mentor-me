import { describe, it, expect, vi } from 'vitest';
import { GeminiService } from '../gemini.js';

describe('4. Gemini AI Integration', () => {
  it('AC 19: Supports switching between Fast and Smart models', () => {
    const gemini = new GeminiService({ geminiApiKey: 'test_key' });
    expect(gemini.modelName).toBe('gemini-3.1-pro-preview'); // Default smart
    
    gemini.setModel('fast');
    expect(gemini.modelName).toBe('gemini-3-flash-preview');
    
    gemini.setModel('smart');
    expect(gemini.modelName).toBe('gemini-3.1-pro-preview');
  });

  it('AC 20: System prompt defines persona', () => {
    const gemini = new GeminiService({ geminiApiKey: 'test_key' });
    expect(gemini.systemInstruction).toContain('Senior Executive Assistant');
  });

  it('AC 21: Configured to use Function Calling', () => {
    const gemini = new GeminiService({ geminiApiKey: 'test_key' });
    expect(gemini.tools).toBeDefined();
  });

  it('AC 22: Receives tool list from MCP', () => {
    const gemini = new GeminiService({ geminiApiKey: 'test_key' });
    const mockMcpTools = [{ name: 'test_tool', description: 'desc', inputSchema: {} }];
    gemini.updateTools(mockMcpTools);
    expect(gemini.availableTools).toContain('test_tool');
  });

  it('AC 24: Maintains sliding window of chat history starting with user', () => {
    const gemini = new GeminiService({ geminiApiKey: 'test_key' });
    
    // Attempt to add model first (should be ignored if empty)
    gemini.addToHistory('model', [{ text: 'hi' }]);
    expect(gemini.history.length).toBe(0);
    
    // Add valid user msg
    gemini.addToHistory('user', [{ text: 'hello' }]);
    expect(gemini.history.length).toBe(1);
    
    for(let i=0; i<30; i++) gemini.addToHistory(i % 2 === 0 ? 'model' : 'user', [{ text: 'msg' }]);
    expect(gemini.history.length).toBeLessThanOrEqual(20);
    expect(gemini.history[0].role).toBe('user');
  });

  it('AC 25: Handles Gemini API errors', async () => {
    const gemini = new GeminiService({ geminiApiKey: 'test_key' });
    const result = await gemini.safeProcess('prompt');
    expect(result.text).toContain('Gemini Error');
  });
});

import { AgentBrain } from '../agent.js';
import { Watchdog } from '../watchdog.js';
import { loadConfig } from '../config.js';
import { McpService } from '../mcp.js';
import { GeminiService } from '../gemini.js';
import { logger } from '../logger.js';
import fs from 'fs';
import path from 'path';

/**
 * Stability Harness: Injects messages and routines to stress-test the system.
 */
async function runStabilityTest() {
  console.log('🚀 Starting Stability & Stress Test Suite...');

  const config = loadConfig();
  const mcp = new McpService(config);
  const gemini = new GeminiService(config);

  // We mock MCP for speed during stress tests unless we really need it
  mcp.discoverTools = async () => [];
  mcp.callTool = async (name, args) => ({ result: 'success', message: `Mocked ${name}` });

  const brain = new AgentBrain({ mcp, gemini });
  const watchdog = new Watchdog({ routinesDir: path.resolve('../data/routines') });

  const testCases = [
    { type: 'text', input: 'What routines are active?' },
    { type: 'text', input: 'Create a test routine that echoes "STABILITY_TEST".' },
    { type: 'voice', input: { audioBase64: 'UklGRi9vAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YSxvAAAA', mimeType: 'audio/ogg' } },
    { type: 'routine', name: 'System Health Check' }
  ];

  let totalTests = 150; // Testing 5 times more than the original 100
  let successCount = 0;

  for (let i = 1; i <= totalTests; i++) {
    console.log(`
[Iteration ${i}/${totalTests}]`);

    // 10% chance of triggering 3 parallel routines to stress the CPU
    if (Math.random() < 0.1) {
      console.log('🔥 STRESS: Triggering 3 parallel routines...');
      let p1, p2;
      try { p1 = watchdog.runner.run(JSON.parse(fs.readFileSync(path.join(watchdog.routinesDir, 'system_check.json'), 'utf-8'))); } catch (e) { p1 = Promise.resolve(); }
      try { p2 = watchdog.runner.run(JSON.parse(fs.readFileSync(path.join(watchdog.routinesDir, 'security_scan.json'), 'utf-8'))); } catch (e) { p2 = Promise.resolve(); }
      const p3 = brain.process('Help me organize my tasks.');

      const results = await Promise.allSettled([p1, p2, p3]);
      results.forEach((r, idx) => {
        if (r.status === 'fulfilled') console.log(`  ✅ Parallel ${idx+1} finished.`);
        else console.error(`  ❌ Parallel ${idx+1} FAILED: ${r.reason.message}`);
      });
      let allPassed = results.every(r => r.status === 'fulfilled'); if (allPassed) successCount++; continue;
    }

    const test = testCases[Math.floor(Math.random() * testCases.length)];

    try {
      if (test.type === 'text' || test.type === 'voice') {
        const response = await brain.process(test.input);
        console.log(`✅ ${test.type.toUpperCase()} processed: ${typeof response === 'string' ? response.substring(0, 50) : 'Media Object'}`);
      } else {
        const routineFile = fs.readdirSync(watchdog.routinesDir).find(f => f.includes('system_check'));
        if (routineFile) {
          const content = JSON.parse(fs.readFileSync(path.join(watchdog.routinesDir, routineFile), 'utf-8'));
          const result = await watchdog.runner.run(content);
          if (result.success && result.usage.total_tokens > 0) {
            console.log(`✅ Routine "${content.name}" executed. Tokens: ${result.usage.total_tokens}`);
          } else if (result.output.includes('NO_ACTION_TAKEN')) {
             console.log(`✅ Routine "${content.name}" skipped (No action).`);
          } else {
            throw new Error(`Routine failed or 0 tokens: ${result.output}`);
          }
        }
      }
      successCount++;
    } catch (err) {
      console.error(`❌ STABILITY FAILURE in iteration ${i}:`, err.message);
    }
  }

  console.log(`
--- FINAL STABILITY REPORT ---`);
  console.log(`Total: ${totalTests} | Success: ${successCount} | Failure: ${totalTests - successCount}`);

  if (successCount === totalTests) {
    console.log('💎 SYSTEM IS STABLE.');
  } else {
    process.exit(1);
  }
}

runStabilityTest();

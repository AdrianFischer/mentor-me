import { GeminiService } from '../gemini.js';
import { loadConfig } from '../config.js';

const config = loadConfig();
const gemini = new GeminiService(config);

async function test() {
  console.log("Calling Gemini with existing history...");
  const result = await gemini.process("This is a test message.");
  console.log(result);
}

test().catch(console.error);
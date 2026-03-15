import { RoutineRunner } from '../routine_runner.js';
import path from 'path';

async function test() {
  console.log('--- Starting Independent Test Harness ---');
  const runner = new RoutineRunner({ logsDir: path.resolve('../logs/routines') });
  
  const routine = {
    name: 'Parser Test',
    task: 'Say exactly "Hello JSON Parsing" and nothing else.',
    timeout: 60
  };

  const result = await runner.run(routine);
  console.log('\n--- Final Parsed Result ---');
  console.log(JSON.stringify(result, null, 2));
}

test();


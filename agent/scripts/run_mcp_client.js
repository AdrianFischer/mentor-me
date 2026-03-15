import { McpService } from '../mcp.js';
import { readFileSync } from 'fs';

async function run() {
  const port = readFileSync(process.env.HOME + '/.assisted_intelligence/mcp_port', 'utf-8').trim();
  const mcp = new McpService({ baseUrl: `http://127.0.0.1:${port}/mcp` });
  await mcp.connect();
  const res = await mcp.callTool('get_projects', {});
  const data = JSON.parse(res.content[0].text);
  
  data.forEach(p => {
    if (!p.isCompleted) {
        console.log(`Active Project: "${p.title}"`);
    }
    p.tasks.forEach(t => {
      if (!t.isCompleted) {
        console.log(`  Active Task: "${t.title}" (ID: ${t.id})`);
      }
      if (t.subtasks) {
          t.subtasks.forEach(st => {
              if (!st.isCompleted) {
                  console.log(`    Active Subtask: "${st.title}"`);
              }
          });
      }
    });
  });
  await mcp.close();
}
run();

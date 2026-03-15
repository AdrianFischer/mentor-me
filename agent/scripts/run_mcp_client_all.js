import { McpService } from '../mcp.js';
import { readFileSync } from 'fs';

async function run() {
  const port = readFileSync(process.env.HOME + '/.assisted_intelligence/mcp_port', 'utf-8').trim();
  const mcp = new McpService({ baseUrl: `http://127.0.0.1:${port}/mcp` });
  await mcp.connect();
  const res = await mcp.callTool('get_projects', {});
  const data = JSON.parse(res.content[0].text);
  
  let found = false;
  data.forEach(p => {
    p.tasks.forEach(t => {
      if (!t.isCompleted) {
          console.log(`Open Task: "${t.title}" (ID: ${t.id}, Project: ${p.title})`);
          console.log(`Notes: ${t.notes}`);
          found = true;
      }
      if (t.subtasks) {
          t.subtasks.forEach(st => {
              if (!st.isCompleted) {
                  console.log(`Open Subtask: "${st.title}" (Task: "${t.title}")`);
                  found = true;
              }
          });
      }
    });
  });
  if (!found) console.log("No tasks with isCompleted == false");
  await mcp.close();
}
run();

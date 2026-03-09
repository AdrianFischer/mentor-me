import { McpService } from './mcp.js';
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
      if (t.aiStatus !== "notReady") {
          console.log(`Task: "${t.title}" aiStatus: ${t.aiStatus} isCompleted: ${t.isCompleted}`);
          found = true;
      }
      if (t.subtasks) {
          t.subtasks.forEach(st => {
              if (st.aiStatus !== "notReady") {
                  console.log(`Subtask: "${st.title}" aiStatus: ${st.aiStatus} isCompleted: ${st.isCompleted}`);
                  found = true;
              }
          });
      }
    });
  });
  if (!found) console.log("No tasks with aiStatus != notReady");
  await mcp.close();
}
run();

import { McpService } from './mcp.js';
import { readFileSync } from 'fs';

async function run() {
  const port = readFileSync(process.env.HOME + '/.assisted_intelligence/mcp_port', 'utf-8').trim();
  const mcp = new McpService({ baseUrl: `http://127.0.0.1:${port}/mcp` });
  await mcp.connect();
  const res = await mcp.callTool('get_projects', {});
  const data = JSON.parse(res.content[0].text);
  
  data.forEach(p => {
    if (!p.isCompleted) {
        console.log(`Active Project: "${p.title}" Notes: ${p.notes}`);
    }
  });
  await mcp.close();
}
run();

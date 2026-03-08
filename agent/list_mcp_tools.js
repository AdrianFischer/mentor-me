import { loadConfig } from './config.js';
import { McpService } from './mcp.js';

async function main() {
  try {
    const config = loadConfig();
    const mcp = new McpService(config);
    await mcp.connect();
    const tools = await mcp.discoverTools();
    console.log(JSON.stringify(tools, null, 2));
    await mcp.close();
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

main();

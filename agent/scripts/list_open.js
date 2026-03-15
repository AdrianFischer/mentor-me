const { execSync } = require('child_process');
const output = execSync('node ./list_mcp_tools.js', { encoding: 'utf-8' });
// wait, list_mcp_tools isn't what I need. Let me just use the output of get_projects via the mcp protocol

const fs = require('fs');

async function check() {
  const req = await fetch('http://127.0.0.1:8081/mcp', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      method: "tools/call",
      params: { name: "get_projects", arguments: {} }
    })
  });
  const text = await req.text();
  console.log(text);
}
check();

const http = require('http');

const req = http.request({
  hostname: '127.0.0.1',
  port: 8081,
  path: '/mcp',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  }
}, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    try {
      const parsed = JSON.parse(data);
      const projects = JSON.parse(parsed.result.output);
      let found = false;
      projects.forEach(p => {
        p.tasks.forEach(t => {
          if (!t.isCompleted) { console.log(`Active Task: ${t.title}`); found=true; }
          t.subtasks && t.subtasks.forEach(st => {
            if (!st.isCompleted) { console.log(`Active Subtask: ${st.title} (in ${t.title})`); found=true; }
          });
        });
      });
      if(!found) console.log("No active tasks found.");
    } catch (e) {
      console.error(e.message, data);
    }
  });
});

req.write(JSON.stringify({
  jsonrpc: "2.0",
  id: 1,
  method: "tools/call",
  params: { name: "get_projects", arguments: {} }
}));
req.end();

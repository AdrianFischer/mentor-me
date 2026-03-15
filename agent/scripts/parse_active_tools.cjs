const fs = require('fs');
const portStr = fs.readFileSync(require('os').homedir() + '/.assisted_intelligence/mcp_port', 'utf8');
const port = parseInt(portStr, 10);
const http = require('http');

http.get(`http://localhost:${port}/mcp`, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    const json = JSON.parse(data);
    let found = false;
    json.projects.forEach(p => {
      p.tasks.forEach(t => {
        if (t.aiStatus === 'ready') {
            console.log(`READY TASK: ${t.id} - ${t.title}`);
            found = true;
        }
        t.subtasks && t.subtasks.forEach(st => {
            if (st.aiStatus === 'ready') {
                console.log(`READY SUBTASK: ${st.id} - ${st.title} (Parent: ${t.title})`);
                found = true;
            }
        });
      });
    });
    if(!found) console.log("NO READY TASKS FOUND.");
  });
});

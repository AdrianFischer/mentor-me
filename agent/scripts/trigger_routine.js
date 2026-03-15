#!/usr/bin/env node

import http from 'http';

const routineName = process.argv[2];

if (!routineName) {
  console.error('Usage: node trigger_routine.js <routine_name_or_file>');
  process.exit(1);
}

const req = http.request({
  hostname: '127.0.0.1',
  port: 8082,
  path: `/api/routines/${encodeURIComponent(routineName)}/trigger`,
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  }
}, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      console.log('✅ Success:', JSON.parse(data).message);
    } else {
      console.error('❌ Error:', res.statusCode, data);
      process.exit(1);
    }
  });
});

req.on('error', (e) => {
  console.error('❌ Request failed:', e.message);
  process.exit(1);
});

req.end();

import express from 'express';
import { fileURLToPath } from 'url';
import path, { dirname } from 'path';
import fs from 'fs';
import http from 'http';
import os from 'os';
import { logger } from './logger.js';
import { GithubTools } from './github_tools.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export class DashboardService {
  constructor(port = 8082, gemini = null) {
    this.port = port;
    this.gemini = gemini;
    this.app = express();
    this.app.use(express.json());
    this.server = null;
    this.githubTools = new GithubTools();
    this._dashboardCache = null;
    this._dashboardCacheTime = 0;
    
    this._setupRoutes();
  }

  setWatchdog(watchdog) {
    this.watchdog = watchdog;
  }

  _setupRoutes() {
    // Serve static files from the 'public' directory
    this.app.use(express.static(path.join(__dirname, 'public')));

    // API Endpoint to trigger a routine on-demand
    this.app.post('/api/routines/:routineName/trigger', async (req, res) => {
      try {
        const routineName = req.params.routineName;
        if (!this.watchdog) {
          return res.status(503).json({ error: 'Watchdog service is not available.' });
        }
        
        const files = fs.readdirSync(this.watchdog.routinesDir).filter(f => f.endsWith('.yaml') || f.endsWith('.json'));
        let foundFile = null;
        let foundRoutine = null;

        for (const file of files) {
          try {
            const routinePath = path.join(this.watchdog.routinesDir, file);
            const content = fs.readFileSync(routinePath, 'utf-8');
            const routine = JSON.parse(content);
            if (routine.name === routineName || file === routineName) {
              foundFile = file;
              foundRoutine = routine;
              break;
            }
          } catch (e) {
            // ignore parse errors for individual files
          }
        }

        if (!foundFile) {
          return res.status(404).json({ error: `Routine '${routineName}' not found.` });
        }

        logger.info(`Dashboard: On-demand trigger for routine: ${foundRoutine.name} (${foundFile})`);
        
        // Execute the routine asynchronously
        this.watchdog.runner.run(foundRoutine).then(result => {
          this.watchdog._handleResult(foundRoutine, result);
        }).catch(err => {
          logger.error(`On-demand routine execution failed for ${foundRoutine.name}`, err);
        });

        res.json({ success: true, message: `Routine '${foundRoutine.name}' triggered.` });
      } catch (error) {
        logger.error('Trigger Routine API Error:', error);
        res.status(500).json({ error: 'Internal Server Error' });
      }
    });

    // API Endpoint for System Status
    this.app.get('/api/system-status', async (req, res) => {
      try {
        const responseData = {
          routines: [],
          configured_routines: [],
          telemetry: [],
          subagents: []
        };

        // 1. Read routines
        const logsDir = path.resolve(__dirname, '../logs/routines');
        const activeTasksFile = path.join(logsDir, 'active_tasks.json');
        
        // Read configured routines
        if (this.watchdog) {
          try {
            const files = fs.readdirSync(this.watchdog.routinesDir).filter(f => f.endsWith('.yaml') || f.endsWith('.json'));
            for (const file of files) {
              try {
                const routinePath = path.join(this.watchdog.routinesDir, file);
                const content = fs.readFileSync(routinePath, 'utf-8');
                const routine = JSON.parse(content);
                responseData.configured_routines.push({
                  filename: file,
                  name: routine.name,
                  execute_every_seconds: routine.execute_every_seconds
                });
              } catch (e) {
                // ignore invalid files
              }
            }
          } catch (e) {
             logger.error('Failed to read configured routines for dashboard', e);
          }
        }

        
        let activeRoutines = {};
        if (fs.existsSync(activeTasksFile)) {
          try {
            activeRoutines = JSON.parse(fs.readFileSync(activeTasksFile, 'utf-8'));
          } catch (e) {
            logger.error('Failed to parse active_tasks.json', e);
          }
        }

        for (const [taskId, data] of Object.entries(activeRoutines)) {
          let isRunning = false;
          try {
            if (data.pid) {
              process.kill(data.pid, 0); // Tests if process exists
              isRunning = true;
            }
          } catch (e) {
            isRunning = false; // Process not running
          }
          
          if (isRunning) {
            responseData.routines.push({
              id: taskId,
              name: data.routine,
              startTime: data.start_time,
              pid: data.pid
            });
          }
        }

        // 2. Read telemetry
        const telemetryFile = path.join(logsDir, 'telemetry.json');
        if (fs.existsSync(telemetryFile)) {
          try {
            const telemetryData = JSON.parse(fs.readFileSync(telemetryFile, 'utf-8'));
            // Get last 5
            responseData.telemetry = telemetryData.slice(-5).reverse();
          } catch (e) {
            logger.error('Failed to parse telemetry.json', e);
          }
        }

        // 3. Subagents (Flutter App/MCP)
        const fetchSubagents = () => {
          return new Promise((resolve) => {
            let mcpPort = 8081; // Default
            try {
              const homeDir = os.homedir();
              const portStr = fs.readFileSync(path.join(homeDir, '.assisted_intelligence', 'mcp_port'), 'utf-8').trim();
              if (portStr) mcpPort = parseInt(portStr, 10);
            } catch (e) {
              // Ignore if file doesn't exist
            }

            const mcpReq = http.request({
              hostname: '127.0.0.1',
              port: mcpPort,
              path: '/mcp',
              method: 'POST',
              headers: {
                'Content-Type': 'application/json'
              },
              timeout: 1000 // Short timeout so dashboard doesn't hang
            }, (mcpRes) => {
              let data = '';
              mcpRes.on('data', chunk => data += chunk);
              mcpRes.on('end', () => {
                try {
                  const parsed = JSON.parse(data);
                  const projects = JSON.parse(parsed.result.output);
                  
                  projects.forEach(p => {
                    p.tasks.forEach(t => {
                      if (t.aiStatus === 'inProgress') {
                        responseData.subagents.push({ title: t.title, project: p.title, type: 'task' });
                      }
                      if (t.subtasks) {
                        t.subtasks.forEach(st => {
                          if (st.aiStatus === 'inProgress') {
                            responseData.subagents.push({ title: st.title, parent: t.title, project: p.title, type: 'subtask' });
                          }
                        });
                      }
                    });
                  });
                  resolve();
                } catch (e) {
                  logger.error('Failed to parse MCP response', e);
                  resolve(); // Still resolve so dashboard continues
                }
              });
            });

            mcpReq.on('error', (e) => {
              // MCP might be down (Flutter app not running)
              logger.debug('MCP Server not responding', e.message);
              resolve(); 
            });

            mcpReq.on('timeout', () => {
              mcpReq.destroy();
              resolve();
            });

            mcpReq.write(JSON.stringify({
              jsonrpc: "2.0",
              id: 1,
              method: "tools/call",
              params: { name: "get_projects", arguments: {} }
            }));
            mcpReq.end();
          });
        };

        await fetchSubagents();
        
        res.json(responseData);
      } catch (error) {
        logger.error('System Status API Error:', error);
        res.status(500).json({ error: 'Internal Server Error' });
      }
    });

    // API Endpoint to fetch log content
    this.app.get('/api/logs', async (req, res) => {
      try {
        const logFile = req.query.file;
        if (!logFile) {
          return res.status(400).json({ error: 'Log file path is required' });
        }
        
        const absolutePath = path.resolve(logFile);
        const logsDir = path.resolve(__dirname, '../logs/routines');
        
        // Security check: ensure path is within logs directory
        if (!absolutePath.startsWith(logsDir)) {
          return res.status(403).json({ error: 'Access denied to paths outside logs directory' });
        }
        
        if (!fs.existsSync(absolutePath)) {
          return res.status(404).json({ error: 'Log file not found' });
        }
        
        const content = fs.readFileSync(absolutePath, 'utf-8');
        res.json({ content });
      } catch (error) {
        logger.error('Log Fetch Error:', error);
        res.status(500).json({ error: 'Internal Server Error' });
      }
    });

    // API Endpoint for Agent Chat
    this.app.post('/api/chat', async (req, res) => {
      try {
        if (!this.gemini) {
          return res.status(503).json({ error: 'Agent service is not available.' });
        }
        
        const { question, context } = req.body;
        if (!question) {
          return res.status(400).json({ error: 'Question is required' });
        }
        
        const prompt = `Context (Log of recent session):\n${context || 'No context provided.'}\n\nUser Question: ${question}\n\nPlease answer the user's question based on the provided session log. Keep your answer concise and helpful.`;
        
        const response = await this.gemini.process([{ text: prompt }], []);
        res.json({ text: response.text });
      } catch (error) {
        logger.error('Chat API Error:', error);
        res.status(500).json({ error: error.message || 'Internal Server Error' });
      }
    });

    // API Endpoint to fetch PR data
    this.app.get('/api/prs', async (req, res) => {
      logger.info('Dashboard: Received request for /api/prs');
      try {
        const repo = req.query.repo || 'noyes-tech/nys_monorepo';
        
        // Return cached response if it's less than 60 seconds old to prevent CLI spam
        const CACHE_TTL = 60 * 1000;
        const timeSinceCache = Date.now() - this._dashboardCacheTime;
        logger.info(`Dashboard: Cache check. Exists: ${!!this._dashboardCache}, Age: ${timeSinceCache}ms`);
        
        if (this._dashboardCache && (timeSinceCache < CACHE_TTL)) {
          logger.info('Dashboard: Returning from cache instantly.');
          return res.json(this._dashboardCache);
        }

        logger.info('Dashboard: Cache miss or expired. Fetching branches...');
        // 1. Fetch open PRs
        const branchesResult = this.githubTools._getBranches({ repo, author: '@me' });
        if (branchesResult.error) {
          logger.error('Dashboard: Error fetching branches', branchesResult.error);
          return res.status(500).json({ error: branchesResult.error, details: branchesResult.details });
        }

        logger.info(`Dashboard: Found ${branchesResult.length} branches. Analyzing...`);
        // 2. Fetch analysis for each PR
        const prsWithAnalysis = [];
        for (const pr of branchesResult) {
          logger.info(`Dashboard: Analyzing PR #${pr.number}...`);
          const analysisText = this.githubTools._analyzePrFailedTests({ 
            repo, 
            pr_number: pr.number,
            branchName: pr.headRefName,
            title: pr.title
          });
          
          // Parse the text output back into a structured format for the UI
          const failedTests = [];
          const lines = analysisText.split('\n');
          let currentTest = null;
          
          for (const line of lines) {
            if (line.startsWith('• `')) {
              if (currentTest) failedTests.push(currentTest);
              currentTest = { 
                name: line.replace('• `', '').replace('`', '').trim(), 
                status: 'unknown',
                details: ''
              };
            } else if (line.includes('⚠️ _Note: This test is also failing on `develop`')) {
               if (currentTest) {
                 currentTest.status = 'known_failure';
                 currentTest.details = line.trim();
               }
            } else if (line.includes('🔴 _This appears to be a new failure')) {
               if (currentTest) {
                 currentTest.status = 'new_failure';
                 currentTest.details = line.trim();
               }
            }
          }
          if (currentTest) failedTests.push(currentTest);

          let overallStatus = 'passing';
          if (analysisText.includes('Could not extract specific pytest failures')) {
             overallStatus = 'build_error';
          } else if (failedTests.length > 0) {
             const hasNewFailures = failedTests.some(t => t.status === 'new_failure');
             overallStatus = hasNewFailures ? 'failing_new' : 'failing_known';
          }

          prsWithAnalysis.push({
            ...pr,
            overallStatus,
            failedTests,
            rawAnalysis: analysisText
          });
        }

        const responsePayload = { prs: prsWithAnalysis };
        this._dashboardCache = responsePayload;
        this._dashboardCacheTime = Date.now();

        logger.info(`Dashboard: Successfully generated response for ${branchesResult.length} PRs.`);
        res.json(responsePayload);
      } catch (error) {
        logger.error('Dashboard API Error:', error);
        res.status(500).json({ error: 'Internal Server Error' });
      }
    });
  }

  start() {
    return new Promise((resolve) => {
      this.server = this.app.listen(this.port, () => {
        logger.info(`📊 Local PR Dashboard running at http://localhost:${this.port}`);
        resolve();
      });
    });
  }

  stop() {
    if (this.server) {
      this.server.close();
      logger.info('📊 Local PR Dashboard stopped.');
    }
  }
}

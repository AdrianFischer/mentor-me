import { execSync } from 'child_process';

export class GithubTools {
  constructor() {
    this._developFailuresCache = null;
    this._developFailuresCacheSha = null;
    this._runFailuresCache = {};
  }

  getTools() {
    return [

      {
        name: 'get_github_pr_details',
        description: 'Fetches details for a specific GitHub Pull Request, such as the branch name (headRefName), status, and title. Useful to find out what branch a PR is associated with.',
        inputSchema: {
          type: 'object',
          properties: {
            repo: { type: 'string', description: 'Optional repository name (e.g. noyes-tech/nys_monorepo). Defaults to local repo if omitted.' },
            pr_number: { type: 'number', description: 'The PR number to fetch details for.' }
          },
          required: ['pr_number']
        }
      },
      {
        name: 'get_github_branches',
        description: 'Fetches a list of Pull Requests from the GitHub repository. Useful to see what PRs are open or authored by specific people.',
        inputSchema: {
          type: 'object',
          properties: {
            repo: { type: 'string', description: 'Optional repository name (e.g. noyes-tech/nys_monorepo). Defaults to local repo if omitted.' },
            limit: { type: 'number', description: 'Number of PRs to fetch (default 10).' },
            state: { type: 'string', description: 'Filter by state: open, closed, merged, or all (default open).' },
            author: { type: 'string', description: 'Filter by author (e.g. @me for your own PRs).' }
          }
        }
      },
      {
        name: 'get_github_pr_comments',
        description: 'Fetches comments for a specific GitHub Pull Request.',
        inputSchema: {
          type: 'object',
          properties: {
            repo: { type: 'string', description: 'Optional repository name (e.g. noyes-tech/nys_monorepo). Defaults to local repo if omitted.' },
            pr_number: { type: 'number', description: 'The PR number to fetch comments for.' }
          },
          required: ['pr_number']
        }
      },
      {
        name: 'get_github_runs',
        description: 'Fetches recent GitHub Actions workflow runs (Cloud Runs / CI).',
        inputSchema: {
          type: 'object',
          properties: {
            repo: { type: 'string', description: 'Optional repository name (e.g. noyes-tech/nys_monorepo). Defaults to local repo if omitted.' },
            limit: { type: 'number', description: 'Number of runs to fetch (default 10).' },
            branch: { type: 'string', description: 'Optional branch name to filter runs by (e.g., develop).' },
            status: { type: 'string', description: 'Optional status filter (e.g., failure, success).' }
          }
        }
      },
      {
        name: 'get_github_failed_run_logs',
        description: 'Fetches the logs for any failed steps in a specific GitHub Actions workflow run.',
        inputSchema: {
          type: 'object',
          properties: {
            repo: { type: 'string', description: 'Optional repository name (e.g. noyes-tech/nys_monorepo). Defaults to local repo if omitted.' },
            run_id: { type: 'number', description: 'The databaseId (run_id) of the run to fetch failed logs for.' },
            lines: { type: 'number', description: 'Number of lines to read from the end of the failed logs (default 500).' }
          },
          required: ['run_id']
        }
      },
      {
        name: 'analyze_pr_failed_tests',
        description: 'Analyzes failed tests for a specific PR. Extracts pytest failures and checks if they are also failing on develop.',
        inputSchema: {
          type: 'object',
          properties: {
            repo: { type: 'string', description: 'Optional repository name (e.g. noyes-tech/nys_monorepo). Defaults to local repo if omitted.' },
            pr_number: { type: 'number', description: 'The PR number to analyze.' }
          },
          required: ['pr_number']
        }
      }
    ];
  }

  async executeTool(call) {
    if (call.name === 'get_github_branches') {
      return this._getBranches(call.args);
    
    } else if (call.name === 'get_github_pr_details') {
      return this._getPrDetails(call.args);
} else if (call.name === 'get_github_pr_comments') {
      return this._getPrComments(call.args);
    } else if (call.name === 'get_github_runs') {
      return this._getRuns(call.args);
    } else if (call.name === 'get_github_failed_run_logs') {
      return this._getFailedRunLogs(call.args);
    } else if (call.name === 'analyze_pr_failed_tests') {
      return this._analyzePrFailedTests(call.args);
    }
    throw new Error('Unknown github tool: ' + call.name);
  }

  _extractFailedTests(logString) {
    if (!logString) return [];
    const lines = logString.split('\n');
    const failedTests = new Set();
    let inSummary = false;
  
    for (let line of lines) {
      if (line.includes('short test summary info')) {
        inSummary = true;
        continue;
      }
      if (inSummary) {
        if (line.includes('===')) inSummary = false; 
        const match = line.match(/(?:FAILED|ERROR)\s+(.*\.py::[^\s]+)/);
        if (match) {
          let testName = match[1];
          testName = testName.split('[')[0];
          failedTests.add(testName);
        }
      }
    }
    return Array.from(failedTests);
  }

  _getDevelopFailures(repo) {
    // 1. Get the latest run on develop to check its commit SHA
    const latestRun = this._runGhCommand(`gh run list -R ${repo} -b develop --limit 1 --json headSha`);
    const currentSha = (latestRun && latestRun.length > 0) ? latestRun[0].headSha : null;

    // Cache develop failures by the latest commit SHA of the develop branch
    if (this._developFailuresCache && this._developFailuresCacheSha === currentSha && currentSha !== null) {
      return this._developFailuresCache;
    }

    const devRuns = this._runGhCommand(`gh run list -R ${repo} -b develop -s failure --limit 10 --json databaseId,createdAt`);
    const developFailures = {};

    if (devRuns && !devRuns.error) {
      for (const run of devRuns) {
        let devFailedTests = this._runFailuresCache[run.databaseId];
        
        if (!devFailedTests) {
          const logs = this._runGhCommandRaw(`gh run view ${run.databaseId} -R ${repo} --log-failed`);
          devFailedTests = this._extractFailedTests(logs);
          this._runFailuresCache[run.databaseId] = devFailedTests;
        }
        
        for (const test of devFailedTests) {
          if (!developFailures[test] || new Date(run.createdAt) < new Date(developFailures[test])) {
            developFailures[test] = run.createdAt;
          }
        }
      }
    }
    
    this._developFailuresCache = developFailures;
    this._developFailuresCacheSha = currentSha;
    return developFailures;
  }

  _analyzePrFailedTests(args) {
    if (!args.pr_number) return { error: 'pr_number is required' };
    const repo = args.repo || 'noyes-tech/nys_monorepo';
    const prNumber = args.pr_number;

    let branchName = args.branchName;
    let prTitle = args.title;

    if (!branchName || !prTitle) {
      const prInfo = this._runGhCommand(`gh pr view ${prNumber} -R ${repo} --json headRefName,title`);
      if (!prInfo || prInfo.error) return { error: `Could not fetch PR #${prNumber}` };
      branchName = prInfo.headRefName;
      prTitle = prInfo.title;
    }

    const prRuns = this._runGhCommand(`gh run list -R ${repo} -b ${branchName} -s failure --limit 1 --json databaseId,createdAt`);
    if (!prRuns || prRuns.length === 0 || prRuns.error) {
      return `No recent failed runs found for PR #${prNumber} (branch: ${branchName}).`;
    }
    const prRunId = prRuns[0].databaseId;

    let prFailedTests = this._runFailuresCache[prRunId];
    if (!prFailedTests) {
      const prLogs = this._runGhCommandRaw(`gh run view ${prRunId} -R ${repo} --log-failed`);
      prFailedTests = this._extractFailedTests(prLogs);
      this._runFailuresCache[prRunId] = prFailedTests;
    }

    if (prFailedTests.length === 0) {
      return `Run ${prRunId} failed, but could not extract specific pytest failures. Might be a build/lint error. Check manually.`;
    }

    // Use cached develop failures to save massive amounts of time
    const developFailures = this._getDevelopFailures(repo);

    let output = `Analysis of PR #${prNumber} ("${prTitle}"):\n\n**Failed Tests:**\n`;
    
    for (const test of prFailedTests) {
      output += `• \`${test}\`\n`;
      if (developFailures[test]) {
        const date = new Date(developFailures[test]).toISOString().split('T')[0];
        output += `   ⚠️ _Note: This test is also failing on \`develop\` (since at least ${date})._\n`;
      } else {
        output += `   🔴 _This appears to be a new failure introduced in this PR._\n`;
      }
    }

    return output;
  }

  _runGhCommand(command) {
    try {
      const output = execSync(command, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] });
      if (!output || output.trim() === '') return [];
      return JSON.parse(output);
    } catch (error) {
      return { 
        error: 'GitHub CLI Error', 
        details: error.stderr ? error.stderr.toString() : error.message 
      };
    }
  }

  _runGhCommandRaw(command) {
    try {
      // Use a larger maxBuffer (e.g., 50MB) to prevent ENOBUFS errors on large outputs
      const output = execSync(command, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'], maxBuffer: 1024 * 1024 * 50 });
      return output;
    } catch (error) {
      return { 
        error: 'GitHub CLI Error', 
        details: error.stderr ? error.stderr.toString() : error.message 
      };
    }
  }

    _getBranches(args) {
    const limit = args.limit || 10;
    const state = args.state || 'open';
    const repoFlag = args.repo ? ` -R ${args.repo}` : '';
    const authorFlag = args.author ? ` --author ${args.author}` : '';
    
    return this._runGhCommand(`gh pr list${repoFlag} --state ${state}${authorFlag} --json number,title,headRefName,updatedAt,state,author --limit ${limit}`);
  }

  
  _getPrDetails(args) {
    if (!args.pr_number) return { error: 'pr_number is required' };
    const repoFlag = args.repo ? ` -R ${args.repo}` : '';
    return this._runGhCommand('gh pr view ' + args.pr_number + repoFlag + ' --json number,title,headRefName,baseRefName,state,author,url');
  }

  _getPrComments(args) {

    if (!args.pr_number) return { error: 'pr_number is required' };
    const repoFlag = args.repo ? ` -R ${args.repo}` : '';
    return this._runGhCommand('gh pr view ' + args.pr_number + repoFlag + ' --comments --json comments');
  }

  _getRuns(args) {
    const limit = args.limit || 10;
    const repoFlag = args.repo ? ` -R ${args.repo}` : '';
    const branchFlag = args.branch ? ` -b ${args.branch}` : '';
    const statusFlag = args.status ? ` -s ${args.status}` : '';
    
    return this._runGhCommand('gh run list' + repoFlag + branchFlag + statusFlag + ' --json databaseId,name,status,conclusion,updatedAt,url,headBranch --limit ' + limit);
  }

    _getFailedRunLogs(args) {
    if (!args.run_id) return { error: 'run_id is required' };
    const repoFlag = args.repo ? ` -R ${args.repo}` : '';
    
    const logs = this._runGhCommandRaw('gh run view ' + args.run_id + repoFlag + ' --log-failed');
    
    if (typeof logs === 'string') {
      const lines = args.lines || 500;
      const logLines = logs.split('\n');
      const tail = logLines.slice(-lines).join('\n');
      
      const maxLength = 100000;
      if (tail.length > maxLength) {
        return `...[Logs truncated to last ${lines} lines / ${maxLength} chars]...\n` + tail.substring(tail.length - maxLength);
      }
      return tail;
    }
    return logs;
  }
}
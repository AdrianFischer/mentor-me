import { execSync } from 'child_process';

export class GithubTools {
  constructor() {}

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
            lines: { type: 'number', description: 'Number of lines to read from the end of the failed logs (default 100).' }
          },
          required: ['run_id']
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
    }
    throw new Error('Unknown github tool: ' + call.name);
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
      const output = execSync(command, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] });
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
      const lines = args.lines || 100;
      const logLines = logs.split('\n');
      const tail = logLines.slice(-lines).join('\n');
      
      const maxLength = 15000;
      if (tail.length > maxLength) {
        return `...[Logs truncated to last ${lines} lines / ${maxLength} chars]...\n` + tail.substring(tail.length - maxLength);
      }
      return tail;
    }
    return logs;
  };
    const repoFlag = args.repo ? ` -R ${args.repo}` : '';
    
    const logs = this._runGhCommandRaw('gh run view ' + args.run_id + repoFlag + ' --log-failed');
    
    if (typeof logs === 'string') {
      const maxLength = 50000;
      if (logs.length > maxLength) {
        return `...[Logs truncated. Showing last ${maxLength} chars]...
` + logs.substring(logs.length - maxLength);
      }
    }
    return logs;
  }
}

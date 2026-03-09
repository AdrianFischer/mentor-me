import { execSync } from 'child_process';

export class GithubTools {
  constructor() {}

  getTools() {
    return [
      {
        name: 'get_github_branches',
        description: 'Fetches recent pull requests and branches from the GitHub repository.',
        inputSchema: { 
          type: 'object', 
          properties: {
            limit: { type: 'number', description: 'Number of PRs/branches to fetch (default 10).' }
          }
        }
      },
      {
        name: 'get_github_pr_comments',
        description: 'Fetches comments for a specific GitHub Pull Request.',
        inputSchema: {
          type: 'object',
          properties: {
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
            limit: { type: 'number', description: 'Number of runs to fetch (default 10).' }
          }
        }
      }
    ];
  }

  async executeTool(call) {
    if (call.name === 'get_github_branches') {
      return this._getBranches(call.args);
    } else if (call.name === 'get_github_pr_comments') {
      return this._getPrComments(call.args);
    } else if (call.name === 'get_github_runs') {
      return this._getRuns(call.args);
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

  _getBranches(args) {
    const limit = args.limit || 10;
    return this._runGhCommand('gh pr list --state all --json number,title,headRefName,updatedAt,state,author --limit ' + limit);
  }

  _getPrComments(args) {
    if (!args.pr_number) return { error: 'pr_number is required' };
    return this._runGhCommand('gh pr view ' + args.pr_number + ' --comments --json comments');
  }

  _getRuns(args) {
    const limit = args.limit || 10;
    return this._runGhCommand('gh run list --json name,status,conclusion,updatedAt,url,headBranch --limit ' + limit);
  }
}

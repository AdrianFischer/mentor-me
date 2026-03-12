import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import { logger } from './logger.js';

/**
 * Manages access to the "Shared" folder, providing tools for file manipulation
 * and terminal command execution restricted to that folder.
 */
export class SharedFolderManager {
  constructor(sharedDir = path.resolve('../data/shared')) {
    this.sharedDir = sharedDir;
    if (!fs.existsSync(this.sharedDir)) {
      fs.mkdirSync(this.sharedDir, { recursive: true });
    }
  }

  getTools() {
    return [
      {
        name: 'list_shared_files',
        description: 'Lists all files and subdirectories within the "Shared" folder.',
        inputSchema: {
          type: 'object',
          properties: {
            subdir: { type: 'string', description: 'Optional subdirectory within the shared folder to list.' }
          }
        }
      },
      {
        name: 'read_shared_file',
        description: 'Reads the content of a file within the "Shared" folder.',
        inputSchema: {
          type: 'object',
          properties: {
            filename: { type: 'string', description: 'The name or relative path of the file to read.' }
          },
          required: ['filename']
        }
      },
      {
        name: 'write_shared_file',
        description: 'Creates or overwrites a file within the "Shared" folder with the provided content.',
        inputSchema: {
          type: 'object',
          properties: {
            filename: { type: 'string', description: 'The name or relative path of the file to write.' },
            content: { type: 'string', description: 'The text content to write into the file.' }
          },
          required: ['filename', 'content']
        }
      },
      {
        name: 'run_shared_command',
        description: 'Executes a terminal command within the "Shared" folder. The command is strictly restricted to this directory.',
        inputSchema: {
          type: 'object',
          properties: {
            command: { type: 'string', description: 'The shell command to execute (e.g., "ls -la", "grep pattern file", "node script.js").' }
          },
          required: ['command']
        }
      }
    ];
  }

  async executeTool(call) {
    try {
      switch (call.name) {
        case 'list_shared_files':
          return this._listSharedFiles(call.args);
        case 'read_shared_file':
          return this._readSharedFile(call.args);
        case 'write_shared_file':
          return this._writeSharedFile(call.args);
        case 'run_shared_command':
          return this._runSharedCommand(call.args);
        default:
          throw new Error(`Unknown shared folder tool: ${call.name}`);
      }
    } catch (error) {
      logger.error(`Error executing shared folder tool ${call.name}:`, error);
      return { result: 'error', message: error.message };
    }
  }

  _resolvePath(relativePath) {
    const resolved = path.resolve(this.sharedDir, relativePath);
    if (!resolved.startsWith(this.sharedDir + path.sep) && resolved !== this.sharedDir) {
      throw new Error(`Access denied: Path "${relativePath}" is outside the "Shared" directory.`);
    }
    return resolved;
  }

  _listSharedFiles(args) {
    const dirToList = args.subdir ? this._resolvePath(args.subdir) : this.sharedDir;
    const entries = fs.readdirSync(dirToList, { withFileTypes: true });
    
    const result = entries.map(entry => ({
      name: entry.name,
      type: entry.isDirectory() ? 'directory' : 'file'
    }));
    
    return { result: 'success', path: args.subdir || '/', entries: result };
  }

  _readSharedFile(args) {
    const filePath = this._resolvePath(args.filename);
    if (!fs.existsSync(filePath)) {
      return { result: 'error', message: `File not found: ${args.filename}` };
    }
    const content = fs.readFileSync(filePath, 'utf-8');
    return { result: 'success', filename: args.filename, content };
  }

  _writeSharedFile(args) {
    const filePath = this._resolvePath(args.filename);
    const parentDir = path.dirname(filePath);
    if (!fs.existsSync(parentDir)) {
      fs.mkdirSync(parentDir, { recursive: true });
    }
    fs.writeFileSync(filePath, args.content, 'utf-8');
    return { result: 'success', message: `File "${args.filename}" written successfully.` };
  }

  _runSharedCommand(args) {
    // This is essentially a restricted shell execution.
    // We execute with the Shared folder as the current working directory.
    try {
      logger.info(`Executing shared command: ${args.command}`);
      const output = execSync(args.command, {
        cwd: this.sharedDir,
        encoding: 'utf-8',
        stdio: ['pipe', 'pipe', 'pipe'], // capture stdout and stderr
        timeout: 30000 // 30 second timeout
      });
      return { result: 'success', output: output.trim() || '(No output)' };
    } catch (error) {
      return { 
        result: 'error', 
        message: 'Command execution failed', 
        details: error.stderr ? error.stderr.toString() : error.message,
        stdout: error.stdout ? error.stdout.toString() : null
      };
    }
  }
}

import fs from 'fs';
import path from 'path';

const LOG_DIR = './logs';
const LOG_FILE = path.join(LOG_DIR, 'agent.log');

if (!fs.existsSync(LOG_DIR)) {
  fs.mkdirSync(LOG_DIR);
}

class Logger {
  log(message, level = 'INFO') {
    const timestamp = new Date().toISOString();
    const formattedMessage = `[${timestamp}] [${level}] ${message}`;
    
    // Print to console
    console.log(formattedMessage);
    
    // Append to file
    try {
      fs.appendFileSync(LOG_FILE, formattedMessage + '\n');
    } catch (err) {
      console.error('Failed to write to log file:', err);
    }
  }

  error(message, error) {
    const errorMsg = error ? `${message}: ${error.stack || error.message || error}` : message;
    this.log(errorMsg, 'ERROR');
  }

  info(message) {
    this.log(message, 'INFO');
  }

  warn(message) {
    this.log(message, 'WARN');
  }

  debug(message) {
    this.log(message, 'DEBUG');
  }
}

export const logger = new Logger();

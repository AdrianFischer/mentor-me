import { logger } from '../logger.js';

/**
 * Error handling middleware for the REST API.
 */
export function errorHandler(err, req, res, _next) {
  logger.error(`API Error [${req.method} ${req.path}]:`, err.message);
  res.status(500).json({ error: 'Internal Server Error' });
}

/**
 * CORS middleware for cross-origin requests (Flutter web, etc).
 */
export function cors(req, res, next) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
}

# Assisted Intelligence Agent

A standalone Node.js service that acts as the "Brain" for the Assisted Intelligence system. It connects your Telegram Bot to the Flutter app via the Model Context Protocol (MCP) and uses Gemini AI for intelligent task management.

## Setup
1. Ensure the Flutter app is running (it provides the MCP server).
2. Set your `TELEGRAM_BOT_TOKEN` and `GEMINI_API_KEY` in `app/.env`.
3. Run `npm install` in this directory.
4. Run `node index.js` to start the agent.

## Testing
Run `npm test` to verify all 50 acceptance criteria.

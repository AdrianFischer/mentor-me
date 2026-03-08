import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { SSEClientTransport } from "@modelcontextprotocol/sdk/client/sse.js";
import { logger } from './logger.js';

export class McpService {
  constructor(config) {
    this.baseUrl = config.baseUrl;
    this.client = new Client(
      { name: "assisted-intelligence-agent", version: "1.0.0" },
      { capabilities: {} }
    );
    this.isConnected = false;
  }

  async connect() {
    try {
      try {
        await this.client.close();
      } catch (e) {}

      this.client = new Client(
        { name: "assisted-intelligence-agent", version: "1.0.0" },
        { capabilities: {} }
      );

      const transport = new SSEClientTransport(new URL(this.baseUrl));
      
      // Add a timeout to the connection
      const connectPromise = this.client.connect(transport);
      const timeoutPromise = new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Connection timeout')), 5000)
      );

      await Promise.race([connectPromise, timeoutPromise]);
      
      this.isConnected = true;
      logger.info(`Connected to MCP at ${this.baseUrl}`);
    } catch (error) {
      logger.error(`MCP Connection error`, error);
      this.isConnected = false;
      throw error;
    }
  }

  async discoverTools() {
    if (!this.isConnected) await this.connect();
    const result = await this.client.listTools();
    return result.tools || [];
  }

  async callTool(name, args) {
    if (!this.isConnected) await this.connect();
    return await this.client.callTool({
      name,
      arguments: args
    });
  }

  async close() {
    await this.client.close();
    this.isConnected = false;
  }
}

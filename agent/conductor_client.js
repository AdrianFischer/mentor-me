import { orkesConductorClient, TaskManager } from '@io-orkes/conductor-javascript';
import { logger } from './logger.js';

export class ConductorManager {
  constructor(config = {}) {
    this.serverUrl = config.serverUrl || 'http://localhost:4748/api';
    this.clientPromise = orkesConductorClient({
      serverUrl: this.serverUrl,
      // Local Agentic Conductor usually doesn't need keyId/keySecret by default
    });
    this.taskManager = null;
    this.workers = [];
  }

  /**
   * Registers and starts workers.
   */
  async startWorkers(workers) {
    try {
      this.workers = workers;
      const client = await this.clientPromise;
      
      this.taskManager = new TaskManager(client, this.workers, {
        logger: logger,
        options: {
          pollInterval: 1000,
          concurrency: 1,
        },
      });
      
      this.taskManager.startPolling();
      logger.info(`Conductor TaskManager started for ${this.workers.length} workers.`);
    } catch (error) {
      logger.error('Failed to start Conductor TaskManager', error);
    }
  }

  async stopWorkers() {
    if (this.taskManager) {
      await this.taskManager.stopPolling();
      logger.info('Conductor TaskManager stopped.');
    }
  }

  /**
   * Dispatches a workflow.
   */
  async startWorkflow(name, input = {}, version = 1) {
    try {
      const client = await this.clientPromise;
      const workflowId = await client.workflowResource.startWorkflow({
        name,
        input,
        version
      });
      logger.info(`Started Conductor workflow: ${name} (ID: ${workflowId})`);
      return workflowId;
    } catch (error) {
      logger.error(`Failed to start workflow ${name}`, error);
      throw error;
    }
  }
}

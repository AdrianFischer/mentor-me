import { logger } from '../logger.js';

/**
 * A Conductor worker that executes a generic AI task using the AgentBrain.
 */
export const createBrainWorker = (brain) => {
  return {
    taskDefName: 'agent_brain_task',
    execute: async (task) => {
      try {
        const { prompt, input, model } = task.inputData;
        logger.info(`Conductor Worker: Executing brain task with prompt: ${prompt || '[Media Input]'}`);

        // Handle optional model override from Conductor
        if (model) {
          brain.setModel(model);
        }

        const response = await brain.process(prompt || input, (status) => {
          // You could optionally report progress back to Conductor here if the SDK supports it
          logger.info(`Conductor Task Status: ${status}`);
        });

        // The response from brain.process can be a string OR a media object { text, imageBase64, ... }
        if (typeof response === 'string') {
          return {
            outputData: { response },
            status: 'COMPLETED'
          };
        } else {
          return {
            outputData: { ...response },
            status: 'COMPLETED'
          };
        }
      } catch (error) {
        logger.error('Conductor Brain Worker Error', error);
        return {
          status: 'FAILED',
          reasonForIncompletion: error.message
        };
      }
    }
  };
};

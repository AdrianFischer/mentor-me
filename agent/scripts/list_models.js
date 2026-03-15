import { GoogleGenerativeAI } from "@google/generative-ai";
import { loadConfig } from '../config.js';

async function listModels() {
  try {
    const config = loadConfig();
    const genAI = new GoogleGenerativeAI(config.geminiApiKey);
    
    // We need to use the base API to list models
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${config.geminiApiKey}`);
    const data = await response.json();
    
    console.log('--- Available Models ---');
    if (data.models) {
      data.models.forEach(model => {
        console.log(`${model.name} - ${model.displayName}`);
        console.log(`   Methods: ${model.supportedGenerationMethods.join(', ')}`);
      });
    } else {
      console.log('No models found or error in response:', data);
    }
  } catch (error) {
    console.error('Error listing models:', error.message);
  }
}

listModels();

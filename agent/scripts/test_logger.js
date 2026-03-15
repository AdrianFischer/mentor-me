import { logger } from '../logger.js';

try {
  console.log('Testing logger methods...');
  logger.info('Test Info');
  logger.warn('Test Warning');
  logger.error('Test Error', new Error('Sample Error'));
  logger.debug('Test Debug');
  console.log('✅ Logger verification successful. All methods exist.');
} catch (e) {
  console.error('❌ Logger verification failed:', e.message);
  process.exit(1);
}

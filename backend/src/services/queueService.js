const aiService = require('./aiService');
const knex = require('../utils/db');

// Keep track of active jobs
const activeJobs = new Set();

/**
 * Process the next job in the queue
 */
const processNextJob = async () => {
  try {
    // Skip if already processing (simple concurrency control)
    if (activeJobs.size >= 2) {
      return;
    }
    
    // Get next job in the queue
    const nextJob = await knex('processing_jobs')
      .where({ status: 'queued' })
      .orderBy('created_at', 'asc')
      .first();
    
    if (!nextJob) {
      return;
    }
    
    // Process the job
    activeJobs.add(nextJob.id);
    try {
      await aiService.processEyeScan(nextJob.scan_id);
    } catch (error) {
      console.error(`Error processing job ${nextJob.id}:`, error);
    } finally {
      activeJobs.delete(nextJob.id);
    }
  } catch (error) {
    console.error('Error in queue processing:', error);
  }
};

// Start the job queue if not in test mode
if (process.env.NODE_ENV !== 'test') {
  // Process queue every 10 seconds
  setInterval(processNextJob, 10000);
  console.log('Processing queue started');
}

module.exports = {
  processNextJob
};
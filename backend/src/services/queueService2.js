/**
 * Queue management service for the IRIS backend.
 * Handles job queuing, processing, and result delivery.
 */

const { v4: uuidv4 } = require('uuid');
const knex = require('../config/knex');
const storageService = require('./storage');

// In-memory queue for processing jobs
// In production, this would typically be replaced by a distributed queue system (e.g., RabbitMQ, Redis, or AWS SQS)
const jobQueue = [];
let isProcessing = false;
const MAX_CONCURRENT_JOBS = 2; // Maximum number of jobs to process concurrently
const activeJobs = new Set();

/**
 * Initialize the queue processor.
 * Starts the interval-based queue checking and loads any pending jobs from the database.
 */
const initialize = () => {
  console.log('Initializing AI processing queue...');
  
  // Start the queue processor—checks the queue every 5 seconds
  setInterval(processQueue, 5000);
  
  // Load any pending jobs from the database
  loadPendingJobs().catch(err => {
    console.error('Error loading pending jobs:', err);
  });
};

/**
 * Load pending jobs from the database.
 */
const loadPendingJobs = async () => {
  try {
    const pendingJobs = await knex('processing_jobs')
      .where({ status: 'queued' })
      .orderBy('created_at', 'asc');
    
    console.log(`Found ${pendingJobs.length} pending jobs`);
    
    // Add pending jobs to the in-memory queue
    pendingJobs.forEach(job => {
      jobQueue.push({
        jobId: job.id,
        scanId: job.scan_id,
        priority: 1, // Default priority
        addedAt: new Date()
      });
    });
  } catch (error) {
    console.error('Error loading pending jobs:', error);
    throw error;
  }
};

/**
 * Process the job queue.
 * Processes jobs if available and if there are fewer than MAX_CONCURRENT_JOBS active.
 */
const processQueue = async () => {
  if (jobQueue.length === 0 || activeJobs.size >= MAX_CONCURRENT_JOBS) {
    return;
  }
  
  try {
    // Sort queue by priority (higher number = higher priority)
    jobQueue.sort((a, b) => b.priority - a.priority);
    
    // Process jobs until either the queue is empty or we hit the concurrency limit
    while (jobQueue.length > 0 && activeJobs.size < MAX_CONCURRENT_JOBS) {
      const job = jobQueue.shift();
      activeJobs.add(job.jobId);
      
      // Process the job asynchronously
      processJob(job.jobId, job.scanId).catch(error => {
        console.error(`Error processing job ${job.jobId}:`, error);
        activeJobs.delete(job.jobId);
      });
    }
  } catch (error) {
    console.error('Error processing queue:', error);
  }
};

/**
 * Add a job to the queue.
 * @param {string} scanId - Scan ID.
 * @param {Object} options - Queue options.
 * @returns {Promise<string>} - Job ID.
 */
const queueJob = async (scanId, options = {}) => {
  try {
    const { priority = 1, userId } = options;
    
    // Validate that the scan exists
    const scan = await knex('eye_scans').where({ id: scanId }).first();
    if (!scan) {
      throw new Error(`Scan not found: ${scanId}`);
    }
    
    // Check if a job already exists for this scan
    const existingJob = await knex('processing_jobs')
      .where({ scan_id: scanId })
      .whereNot({ status: 'failed' })
      .first();
    
    if (existingJob) {
      return existingJob.id;
    }
    
    // Create a new processing job record in the database
    const jobId = uuidv4();
    await knex('processing_jobs').insert({
      id: jobId,
      scan_id: scanId,
      status: 'queued',
      progress: 0,
      created_at: knex.fn.now(),
      updated_at: knex.fn.now()
    });
    
    // Add the job to the in-memory queue
    jobQueue.push({
      jobId,
      scanId,
      priority,
      addedAt: new Date()
    });
    
    // Log an audit event if userId is provided
    if (userId) {
      await knex('audit_logs').insert({
        id: uuidv4(),
        user_id: userId,
        action: 'create',
        resource_type: 'processing_job',
        resource_id: jobId,
        details: JSON.stringify({ scan_id: scanId, priority }),
        created_at: knex.fn.now()
      });
    }
    
    return jobId;
  } catch (error) {
    console.error('Error queuing job:', error);
    throw error;
  }
};

/**
 * Process a job.
 * Updates job progress as it processes a scan and saves the results.
 * @param {string} jobId - Job ID.
 * @param {string} scanId - Scan ID.
 */
const processJob = async (jobId, scanId) => {
  try {
    console.log(`Processing job ${jobId} for scan ${scanId}`);
    
    // Update job status to "processing"
    await updateJobStatus(jobId, 'processing', { started_at: knex.fn.now() });
    
    // Retrieve the scan image using the storageService
    const scanResult = await storageService.retrieveEyeScan(scanId);
    if (!scanResult) {
      throw new Error(`Failed to retrieve scan image: ${scanId}`);
    }
    
    // Simulate step-by-step progress updates
    await updateJobProgress(jobId, 10, 'Analyzing image characteristics');
    await sleep(1000);
    
    await updateJobProgress(jobId, 30, 'Processing retinal patterns');
    await sleep(1000);
    
    await updateJobProgress(jobId, 50, 'Detecting potential conditions');
    await sleep(1000);
    
    await updateJobProgress(jobId, 70, 'Generating diagnostic report');
    await sleep(1000);
    
    await updateJobProgress(jobId, 90, 'Finalizing analysis results');
    await sleep(1000);
    
    // Generate mock results to simulate AI analysis
    const results = generateMockResults(scanId);
    
    // Save the diagnostic results to the database
    await saveResults(scanId, results);
    
    // Update job status to "completed" (100% progress)
    await updateJobStatus(jobId, 'completed', {
      progress: 100,
      completed_at: knex.fn.now()
    });
    
    console.log(`Job ${jobId} completed successfully`);
  } catch (error) {
    console.error(`Error processing job ${jobId}:`, error);
    // Update job status to "failed" and store error message
    await updateJobStatus(jobId, 'failed', { error_message: error.message });
  } finally {
    activeJobs.delete(jobId);
  }
};

/**
 * Update the status of a job.
 * @param {string} jobId - Job ID.
 * @param {string} status - New status.
 * @param {Object} additionalData - Additional data to update.
 */
const updateJobStatus = async (jobId, status, additionalData = {}) => {
  try {
    await knex('processing_jobs')
      .where({ id: jobId })
      .update({
        status,
        updated_at: knex.fn.now(),
        ...additionalData
      });
  } catch (error) {
    console.error(`Error updating job ${jobId} status:`, error);
    throw error;
  }
};

/**
 * Update the job progress.
 * @param {string} jobId - Job ID.
 * @param {number} progress - Progress percentage (0–100).
 * @param {string} message - Progress message.
 */
const updateJobProgress = async (jobId, progress, message) => {
  try {
    await knex('processing_jobs')
      .where({ id: jobId })
      .update({
        progress,
        updated_at: knex.fn.now()
      });
    
    console.log(`Job ${jobId} progress: ${progress}% - ${message}`);
  } catch (error) {
    console.error(`Error updating job ${jobId} progress:`, error);
    throw error;
  }
};

/**
 * Save diagnostic results and recommendations to the database.
 * Also updates the scan record with image quality.
 * @param {string} scanId - Scan ID.
 * @param {Object} results - Analysis results.
 * @returns {Promise<string>} - Diagnostic result ID.
 */
const saveResults = async (scanId, results) => {
  try {
    const resultId = uuidv4();
    
    // Insert diagnostic result
    await knex('diagnostic_results').insert({
      id: resultId,
      scan_id: scanId,
      condition: results.condition,
      confidence: results.confidence,
      severity: results.severity,
      diagnosis: results.diagnosis,
      processing_time: results.processingTime,
      ai_model_version: results.aiModelVersion,
      created_at: knex.fn.now(),
      updated_at: knex.fn.now()
    });
    
    // Insert recommendations
    for (let i = 0; i < results.recommendations.length; i++) {
      await knex('recommendations').insert({
        id: uuidv4(),
        result_id: resultId,
        recommendation: results.recommendations[i],
        priority: i + 1,
        created_at: knex.fn.now(),
        updated_at: knex.fn.now()
      });
    }
    
    // Update the eye scan record with the image quality metric
    await knex('eye_scans')
      .where({ id: scanId })
      .update({
        image_quality: results.imageQuality,
        updated_at: knex.fn.now()
      });
    
    return resultId;
  } catch (error) {
    console.error(`Error saving results for scan ${scanId}:`, error);
    throw error;
  }
};

/**
 * Generate mock analysis results.
 * @param {string} scanId - Scan ID.
 * @returns {Object} - Mock results.
 */
const generateMockResults = (scanId) => {
  const conditions = [
    {
      condition: 'normal',
      confidence: 0.95,
      severity: 'none',
      diagnosis: 'No abnormalities detected in the eye scan. Your eyes appear to be healthy.',
      recommendations: [
        'Continue with regular eye check-ups every 12-24 months',
        'Maintain a healthy lifestyle with foods rich in vitamins A, C, and E',
        'Use proper eye protection in bright sunlight',
        'Take regular breaks when using digital screens (20-20-20 rule)'
      ]
    },
    {
      condition: 'conjunctivitis',
      confidence: 0.88,
      severity: 'low',
      diagnosis: "Signs of conjunctivitis detected. This condition involves inflammation of the eye's conjunctiva.",
      recommendations: [
        'Consult an ophthalmologist within 24-48 hours',
        'Avoid touching or rubbing your eyes',
        'Wash hands frequently to prevent spread',
        'Cold compresses may help reduce discomfort',
        'Dispose of eye makeup and avoid sharing towels/pillows'
      ]
    },
    {
      condition: 'glaucoma',
      confidence: 0.92,
      severity: 'moderate',
      diagnosis: 'Potential indicators of glaucoma present. Increased pressure in the eye may damage the optic nerve.',
      recommendations: [
        'Schedule an appointment with an ophthalmologist immediately',
        'This condition requires professional monitoring and treatment',
        'Early treatment can prevent vision loss',
        'Adherence to prescribed eye drops is crucial if diagnosed'
      ]
    },
    {
      condition: 'cataract',
      confidence: 0.90,
      severity: 'low',
      diagnosis: "Cataract formation detected. Cataracts cause clouding of the eye's lens, resulting in blurry vision.",
      recommendations: [
        'Schedule an appointment with an ophthalmologist',
        'Cataracts typically progress slowly and can be monitored',
        'Consider surgery when vision impairment affects daily activities',
        'Use anti-glare sunglasses in bright light',
        'Ensure adequate lighting for reading and close work'
      ]
    },
    {
      condition: 'diabeticRetinopathy',
      confidence: 0.87,
      severity: 'high',
      diagnosis: 'Signs of diabetic retinopathy observed. This condition affects blood vessels in the retina and is related to diabetes.',
      recommendations: [
        'Consult with both your endocrinologist and ophthalmologist',
        'Maintain strict blood sugar control',
        'Regular eye examinations are crucial - every 6-12 months',
        'Control blood pressure and cholesterol levels',
        'Follow a diabetic-friendly diet and exercise plan'
      ]
    }
  ];
  
  const randomIndex = Math.floor(Math.random() * conditions.length);
  const selectedCondition = conditions[randomIndex];
  
  return {
    ...selectedCondition,
    processingTime: Math.floor(Math.random() * 5000) + 2000, // 2000-7000 ms
    aiModelVersion: '2.0.0',
    imageQuality: Math.floor(Math.random() * 20) + 80 // 80-100
  };
};

/**
 * Sleep for a specified duration.
 * @param {number} ms - Milliseconds to sleep.
 * @returns {Promise<void>}
 */
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

/**
 * Get the status of a job.
 * @param {string} jobId - Job ID.
 * @returns {Promise<Object>} - Job status.
 */
const getJobStatus = async (jobId) => {
  try {
    const job = await knex('processing_jobs').where({ id: jobId }).first();
    if (!job) {
      throw new Error(`Job not found: ${jobId}`);
    }
    return job;
  } catch (error) {
    console.error(`Error getting job ${jobId} status:`, error);
    throw error;
  }
};

/**
 * Cancel a job.
 * @param {string} jobId - Job ID.
 * @returns {Promise<boolean>} - True if job was cancelled.
 */
const cancelJob = async (jobId) => {
  try {
    const job = await knex('processing_jobs').where({ id: jobId }).first();
    if (!job) {
      throw new Error(`Job not found: ${jobId}`);
    }
    if (job.status === 'completed' || job.status === 'failed') {
      throw new Error(`Cannot cancel job with status: ${job.status}`);
    }
    
    // Remove from the in-memory queue if job is still queued
    if (job.status === 'queued') {
      const index = jobQueue.findIndex(queuedJob => queuedJob.jobId === jobId);
      if (index !== -1) {
        jobQueue.splice(index, 1);
      }
    }
    
    // Update job status to "cancelled"
    await knex('processing_jobs')
      .where({ id: jobId })
      .update({
        status: 'cancelled',
        error_message: 'Job cancelled by user',
        updated_at: knex.fn.now()
      });
    
    activeJobs.delete(jobId);
    return true;
  } catch (error) {
    console.error(`Error cancelling job ${jobId}:`, error);
    throw error;
  }
};

// Automatically initialize the queue processor when this module is loaded.
initialize();

module.exports = {
  queueJob,
  getJobStatus,
  cancelJob,
  updateJobProgress // Exporting in case manual progress updates are desired elsewhere
};

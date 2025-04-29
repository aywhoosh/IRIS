/**
 * Processing controller for the IRIS backend
 * Handles image processing jobs and AI analysis
 */
const { v4: uuidv4 } = require('uuid');
const knex = require('../config/knex');
const storageService = require('../services/storage');

/**
 * Create a new processing job
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
const createProcessingJob = async (req, res) => {
  try {
    const { scanId } = req.body;
    
    if (!scanId) {
      return res.status(400).json({
        success: false,
        message: 'Scan ID is required'
      });
    }
    
    // Check if scan exists
    const scan = await knex('eye_scans')
      .where({ id: scanId })
      .first();
    
    if (!scan) {
      return res.status(404).json({
        success: false,
        message: 'Scan not found'
      });
    }
    
    // Check if user has access to this scan
    if (req.user.id !== scan.patient_id) {
      // Check if user is a doctor
      const userRole = await knex('users')
        .where({ id: req.user.id })
        .first('role');
      
      if (!userRole || userRole.role !== 'doctor') {
        return res.status(403).json({
          success: false,
          message: 'Access denied'
        });
      }
    }
    
    // Check if a processing job already exists for this scan
    const existingJob = await knex('processing_jobs')
      .where({ scan_id: scanId })
      .whereNot({ status: 'failed' })
      .first();
    
    if (existingJob) {
      return res.status(409).json({
        success: false,
        message: 'A processing job already exists for this scan',
        data: {
          jobId: existingJob.id,
          status: existingJob.status,
          progress: existingJob.progress
        }
      });
    }
    
    // Create a new processing job
    const jobId = uuidv4();
    
    await knex('processing_jobs').insert({
      id: jobId,
      scan_id: scanId,
      status: 'queued',
      progress: 0,
      created_at: knex.fn.now(),
      updated_at: knex.fn.now()
    });
    
    // Log audit event
    await knex('audit_logs').insert({
      id: uuidv4(),
      user_id: req.user.id,
      action: 'create',
      resource_type: 'processing_job',
      resource_id: jobId,
      details: JSON.stringify({
        scan_id: scanId
      }),
      ip_address: req.ip,
      user_agent: req.headers['user-agent'],
      created_at: knex.fn.now()
    });
    
    // Return job details
    res.status(201).json({
      success: true,
      message: 'Processing job created successfully',
      data: {
        jobId,
        scanId,
        status: 'queued',
        progress: 0,
        createdAt: new Date().toISOString()
      }
    });
    
    // Trigger processing in background (non-blocking)
    processImage(jobId, scanId).catch(error => {
      console.error(`Error processing image for job ${jobId}:`, error);
    });
  } catch (error) {
    console.error('Error creating processing job:', error);
    
    res.status(500).json({
      success: false,
      message: 'Error creating processing job',
      error: error.message
    });
  }
};

/**
 * Get processing job status
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
const getProcessingJobStatus = async (req, res) => {
  try {
    const { jobId } = req.params;
    
    // Get job from database
    const job = await knex('processing_jobs')
      .where({ id: jobId })
      .first();
    
    if (!job) {
      return res.status(404).json({
        success: false,
        message: 'Processing job not found'
      });
    }
    
    // Get scan to check access
    const scan = await knex('eye_scans')
      .where({ id: job.scan_id })
      .first();
    
    // Check if user has access to this job
    if (req.user.id !== scan.patient_id) {
      // Check if user is a doctor
      const userRole = await knex('users')
        .where({ id: req.user.id })
        .first('role');
      
      if (!userRole || userRole.role !== 'doctor') {
        return res.status(403).json({
          success: false,
          message: 'Access denied'
        });
      }
    }
    
    // Get diagnostic result if job is completed
    let diagnosticResult = null;
    let recommendations = [];
    
    if (job.status === 'completed') {
      diagnosticResult = await knex('diagnostic_results')
        .where({ scan_id: job.scan_id })
        .first();
      
      if (diagnosticResult) {
        recommendations = await knex('recommendations')
          .where({ result_id: diagnosticResult.id })
          .orderBy('priority', 'asc')
          .select('recommendation', 'priority');
      }
    }
    
    // Return job status
    res.status(200).json({
      success: true,
      data: {
        jobId: job.id,
        scanId: job.scan_id,
        status: job.status,
        progress: job.progress,
        error: job.error_message,
        startedAt: job.started_at,
        completedAt: job.completed_at,
        createdAt: job.created_at,
        updatedAt: job.updated_at,
        diagnosticResult: diagnosticResult ? {
          id: diagnosticResult.id,
          condition: diagnosticResult.condition,
          confidence: diagnosticResult.confidence,
          severity: diagnosticResult.severity,
          diagnosis: diagnosticResult.diagnosis,
          aiModelVersion: diagnosticResult.ai_model_version,
          createdAt: diagnosticResult.created_at
        } : null,
        recommendations: recommendations.map(rec => ({
          recommendation: rec.recommendation,
          priority: rec.priority
        }))
      }
    });
  } catch (error) {
    console.error('Error getting processing job status:', error);
    
    res.status(500).json({
      success: false,
      message: 'Error getting processing job status',
      error: error.message
    });
  }
};

/**
 * Cancel a processing job
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
const cancelProcessingJob = async (req, res) => {
  try {
    const { jobId } = req.params;
    
    // Get job from database
    const job = await knex('processing_jobs')
      .where({ id: jobId })
      .first();
    
    if (!job) {
      return res.status(404).json({
        success: false,
        message: 'Processing job not found'
      });
    }
    
    // Get scan to check access
    const scan = await knex('eye_scans')
      .where({ id: job.scan_id })
      .first();
    
    // Check if user has access to this job
    if (req.user.id !== scan.patient_id) {
      // Check if user is a doctor
      const userRole = await knex('users')
        .where({ id: req.user.id })
        .first('role');
      
      if (!userRole || userRole.role !== 'doctor') {
        return res.status(403).json({
          success: false,
          message: 'Access denied'
        });
      }
    }
    
    // Check if job can be cancelled
    if (job.status === 'completed' || job.status === 'failed') {
      return res.status(400).json({
        success: false,
        message: `Cannot cancel job with status: ${job.status}`
      });
    }
    
    // Update job status
    await knex('processing_jobs')
      .where({ id: jobId })
      .update({
        status: 'cancelled',
        error_message: 'Job cancelled by user',
        updated_at: knex.fn.now()
      });
    
    // Log audit event
    await knex('audit_logs').insert({
      id: uuidv4(),
      user_id: req.user.id,
      action: 'cancel',
      resource_type: 'processing_job',
      resource_id: jobId,
      ip_address: req.ip,
      user_agent: req.headers['user-agent'],
      created_at: knex.fn.now()
    });
    
    // Return success
    res.status(200).json({
      success: true,
      message: 'Processing job cancelled successfully'
    });
  } catch (error) {
    console.error('Error cancelling processing job:', error);
    
    res.status(500).json({
      success: false,
      message: 'Error cancelling processing job',
      error: error.message
    });
  }
};

/**
 * Get all processing jobs for a user
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
const getUserProcessingJobs = async (req, res) => {
  try {
    const { userId } = req.params;
    const { status, limit = 10, offset = 0 } = req.query;
    
    // Check if user has access to this data
    if (req.user.id !== userId) {
      // Check if user is a doctor
      const userRole = await knex('users')
        .where({ id: req.user.id })
        .first('role');
      
      if (!userRole || userRole.role !== 'doctor') {
        return res.status(403).json({
          success: false,
          message: 'Access denied'
        });
      }
    }
    
    // Build query to get scans for this user
    const scanQuery = knex('eye_scans')
      .where({ patient_id: userId })
      .select('id');
    
    // Get scan IDs
    const scans = await scanQuery;
    const scanIds = scans.map(scan => scan.id);
    
    if (scanIds.length === 0) {
      return res.status(200).json({
        success: true,
        data: {
          jobs: [],
          pagination: {
            total: 0,
            limit: parseInt(limit, 10),
            offset: parseInt(offset, 10),
            hasMore: false
          }
        }
      });
    }
    
    // Build query for jobs
    const jobQuery = knex('processing_jobs')
      .whereIn('scan_id', scanIds)
      .orderBy('created_at', 'desc')
      .limit(parseInt(limit, 10))
      .offset(parseInt(offset, 10));
    
    // Filter by status if provided
    if (status) {
      jobQuery.where({ status });
    }
    
    // Get jobs
    const jobs = await jobQuery;
    
    // Get total count
    const countQuery = knex('processing_jobs')
      .whereIn('scan_id', scanIds)
      .count('id as total');
    
    if (status) {
      countQuery.where({ status });
    }
    
    const [{ total }] = await countQuery;
    
    // Return jobs
    res.status(200).json({
      success: true,
      data: {
        jobs: jobs.map(job => ({
          id: job.id,
          scanId: job.scan_id,
          status: job.status,
          progress: job.progress,
          error: job.error_message,
          startedAt: job.started_at,
          completedAt: job.completed_at,
          createdAt: job.created_at,
          updatedAt: job.updated_at
        })),
        pagination: {
          total: parseInt(total, 10),
          limit: parseInt(limit, 10),
          offset: parseInt(offset, 10),
          hasMore: parseInt(offset, 10) + jobs.length < parseInt(total, 10)
        }
      }
    });
  } catch (error) {
    console.error('Error getting user processing jobs:', error);
    
    res.status(500).json({
      success: false,
      message: 'Error getting user processing jobs',
      error: error.message
    });
  }
};

/**
 * Process an image (background task)
 * @param {string} jobId - Processing job ID
 * @param {string} scanId - Eye scan ID
 */
const processImage = async (jobId, scanId) => {
  try {
    // Update job status to processing
    await knex('processing_jobs')
      .where({ id: jobId })
      .update({
        status: 'processing',
        started_at: knex.fn.now(),
        updated_at: knex.fn.now()
      });
    
    // Get scan data
    const scan = await knex('eye_scans')
      .where({ id: scanId })
      .first();
    
    if (!scan) {
      throw new Error(`Scan not found: ${scanId}`);
    }
    
    // Simulate processing steps with progress updates
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
    
    // Generate mock diagnostic result
    // In a real implementation, this would call the AI model
    const mockResults = generateMockDiagnosticResults(scan.eye_side);
    
    // Create diagnostic result record
    const resultId = uuidv4();
    
    await knex('diagnostic_results').insert({
      id: resultId,
      scan_id: scanId,
      condition: mockResults.condition,
      confidence: mockResults.confidence,
      severity: mockResults.severity,
      diagnosis: mockResults.diagnosis,
      processing_time: Math.floor(Math.random() * 5000) + 2000, // 2-7 seconds
      ai_model_version: '2.0.0',
      created_at: knex.fn.now(),
      updated_at: knex.fn.now()
    });
    
    // Create recommendations
    for (let i = 0; i < mockResults.recommendations.length; i++) {
      await knex('recommendations').insert({
        id: uuidv4(),
        result_id: resultId,
        recommendation: mockResults.recommendations[i],
        priority: i + 1,
        created_at: knex.fn.now(),
        updated_at: knex.fn.now()
      });
    }
    
    // Update job status to completed
    await knex('processing_jobs')
      .where({ id: jobId })
      .update({
        status: 'completed',
        progress: 100,
        completed_at: knex.fn.now(),
        updated_at: knex.fn.now()
      });
    
    console.log(`Processing job ${jobId} completed successfully`);
  } catch (error) {
    console.error(`Error processing image for job ${jobId}:`, error);
    
    // Update job status to failed
    await knex('processing_jobs')
      .where({ id: jobId })
      .update({
        status: 'failed',
        error_message: error.message,
        updated_at: knex.fn.now()
      });
  }
};

/**
 * Update job progress
 * @param {string} jobId - Processing job ID
 * @param {number} progress - Progress percentage (0-100)
 * @param {string} message - Progress message
 */
const updateJobProgress = async (jobId, progress, message) => {
  await knex('processing_jobs')
    .where({ id: jobId })
    .update({
      progress,
      updated_at: knex.fn.now()
    });
  
  console.log(`Job ${jobId} progress: ${progress}% - ${message}`);
};

/**
 * Sleep for a specified duration
 * @param {number} ms - Milliseconds to sleep
 * @returns {Promise<void>}
 */
const sleep = (ms) => {
  return new Promise(resolve => setTimeout(resolve, ms));
};

/**
 * Generate mock diagnostic results
 * @param {string} eyeSide - Eye side (left or right)
 * @returns {Object} - Mock diagnostic results
 */
const generateMockDiagnosticResults = (eyeSide) => {
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
      diagnosis: 'Signs of conjunctivitis detected. This condition involves inflammation of the eye\'s conjunctiva.',
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
      diagnosis: 'Potential indicators of glaucoma present. Glaucoma is caused by increased pressure in the eye damaging the optic nerve.',
      recommendations: [
        'Schedule an appointment with an ophthalmologist immediately',
        'This condition requires
(Content truncated due to size limit. Use line ranges to read in chunks)
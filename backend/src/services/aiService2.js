/**
 * Merged Eye Scan Processing Service for the IRIS backend.
 *
 * This module takes a scan ID, updates job progress, retrieves the scan image,
 * runs an AI analysis pipeline to detect conditions, writes diagnostic results and
 * recommendations to the database, and finally updates the scan and job status.
 *
 * Concepts from file 1 (advanced analysis functions) are combined with the progress
 * updates and job management logic from file 2.
 */

const fs = require('fs');
const sharp = require('sharp');
const { v4: uuidv4 } = require('uuid');
const knex = require('../utils/db'); // or use '../config/knex' as needed

// Optional: if you have a storage service for retrieving scan images,
// you could require it here. For now we assume the scan record contains an image_path.
// const storageService = require('./storage');

/**
 * Sleep helper to simulate processing delays.
 * @param {number} ms - milliseconds to sleep
 * @returns {Promise<void>}
 */
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

/**
 * Analyze a retinal image.
 * Implements a simple AI pipeline:
 * 1. Preprocess the image.
 * 2. Run model inference (simulated here).
 * 3. Post-process the results.
 * 4. Format the final output.
 *
 * @param {Buffer|string} imageData - Image data (buffer or file path)
 * @param {Object} options - Optional parameters (e.g., eyeSide)
 * @returns {Promise<Object>} - Formatted analysis results
 */
const analyzeRetinalImage = async (imageData, options = {}) => {
  try {
    console.log('Analyzing retinal image...');
    
    // 1. Preprocess the image (resize, normalize, etc.)
    const preprocessedImage = await preprocessImage(imageData);
    
    // 2. Simulate model inference
    const modelResults = await runModelInference(preprocessedImage);
    
    // 3. Post-process the raw model output
    const results = postprocessResults(modelResults);
    
    // 4. Format the results for storage/display
    return formatResults(results);
  } catch (error) {
    console.error('Error analyzing retinal image:', error);
    throw error;
  }
};

/**
 * Preprocess the image.
 * @param {Buffer|string} imageData - Buffer or filepath to the image
 * @returns {Promise<Buffer>} - Preprocessed image buffer (resized to 224x224)
 */
const preprocessImage = async (imageData) => {
  try {
    // Load the image: if already a buffer use it, otherwise read from file
    const imageBuffer = Buffer.isBuffer(imageData)
      ? imageData
      : await fs.promises.readFile(imageData);
    
    // Resize to 224x224 (for many vision models)
    const resizedImage = await sharp(imageBuffer)
      .resize(224, 224, {
        fit: 'contain',
        background: { r: 0, g: 0, b: 0, alpha: 1 }
      })
      .toBuffer();
    
    return resizedImage;
  } catch (error) {
    console.error('Error preprocessing image:', error);
    throw error;
  }
};

/**
 * Simulate model inference.
 * In an actual implementation, load your deep-learning model and run inference.
 * @param {Buffer} preprocessedImage - Preprocessed image buffer.
 * @returns {Promise<Object>} - Raw model output (simulated).
 */
const runModelInference = async (preprocessedImage) => {
  try {
    await sleep(2000); // simulate processing delay
    
    // Generate mock conditions with random probabilities
    const conditions = [
      { name: 'normal', probability: Math.random() },
      { name: 'diabeticRetinopathy', probability: Math.random() },
      { name: 'glaucoma', probability: Math.random() },
      { name: 'cataract', probability: Math.random() },
      { name: 'conjunctivitis', probability: Math.random() }
    ];
    
    // Normalize probabilities to sum to 1
    const sum = conditions.reduce((acc, condition) => acc + condition.probability, 0);
    conditions.forEach(condition => {
      condition.probability = condition.probability / sum;
    });
    
    // Sort conditions by descending probability
    conditions.sort((a, b) => b.probability - a.probability);
    
    return {
      conditions,
      imageQuality: Math.floor(Math.random() * 20) + 80, // e.g. 80-100
      processingTime: Date.now()
    };
  } catch (error) {
    console.error('Error running model inference:', error);
    throw error;
  }
};

/**
 * Post-process the model results.
 * Determines the top condition and sets a severity level.
 * @param {Object} modelResults - Raw model output.
 * @returns {Object} - Post-processed results.
 */
const postprocessResults = (modelResults) => {
  try {
    const topCondition = modelResults.conditions[0];
    
    let severity;
    if (topCondition.name === 'normal') {
      severity = 'none';
    } else if (topCondition.probability > 0.9) {
      severity = 'high';
    } else if (topCondition.probability > 0.7) {
      severity = 'moderate';
    } else {
      severity = 'low';
    }
    
    return {
      condition: topCondition.name,
      confidence: topCondition.probability,
      severity,
      allConditions: modelResults.conditions,
      imageQuality: modelResults.imageQuality,
      processingTime: Date.now() - modelResults.processingTime
    };
  } catch (error) {
    console.error('Error post-processing results:', error);
    throw error;
  }
};

/**
 * Format the results with human-readable descriptions and recommendations.
 * @param {Object} results - Post-processed results.
 * @returns {Object} - Formatted analysis results.
 */
const formatResults = (results) => {
  try {
    const conditionDescriptions = {
      normal: 'No abnormalities detected in the eye scan. Your eyes appear to be healthy.',
      conjunctivitis: 'Signs of conjunctivitis detected. This condition involves inflammation of the eye\'s conjunctiva.',
      glaucoma: 'Potential indicators of glaucoma present. Increased pressure in the eye may damage the optic nerve.',
      cataract: 'Cataract formation detected, which causes clouding of the lens and blurry vision.',
      diabeticRetinopathy: 'Signs of diabetic retinopathy observed. This condition affects the blood vessels in the retina.'
    };
    
    const recommendations = {
      normal: [
        'Continue with regular eye check-ups every 12-24 months.',
        'Maintain a healthy, vitamin-rich diet.',
        'Wear proper eye protection in bright sunlight.',
        'Follow the 20-20-20 rule when using screens.'
      ],
      conjunctivitis: [
        'Consult an ophthalmologist within 24-48 hours.',
        'Avoid touching or rubbing your eyes.',
        'Wash your hands frequently.',
        'Apply cold compresses to reduce discomfort.'
      ],
      glaucoma: [
        'Schedule an appointment with an ophthalmologist immediately.',
        'Early treatment can prevent vision loss.',
        'Follow any prescribed treatment diligently.'
      ],
      cataract: [
        'Consult an ophthalmologist for monitoring.',
        'Consider surgery if vision impairment worsens.',
        'Use anti-glare sunglasses in bright conditions.'
      ],
      diabeticRetinopathy: [
        'Consult both your endocrinologist and ophthalmologist.',
        'Maintain strict blood sugar control.',
        'Schedule regular eye examinations every 6-12 months.'
      ]
    };
    
    return {
      condition: results.condition,
      confidence: results.confidence,
      severity: results.severity,
      diagnosis: conditionDescriptions[results.condition] || 'Analysis complete. Please consult a healthcare professional.',
      recommendations: recommendations[results.condition] || ['Consult with an ophthalmologist for further evaluation.'],
      imageQuality: results.imageQuality,
      processingTime: results.processingTime,
      aiModelVersion: '2.0.0',
      analysisTimestamp: new Date().toISOString()
    };
  } catch (error) {
    console.error('Error formatting results:', error);
    throw error;
  }
};

/**
 * Process an eye scan.
 *
 * Main function that:
 * 1. Retrieves the scan from the database.
 * 2. Updates the processing job status (progress 25% -> 75% -> 100%).
 * 3. Retrieves the scan image (assumed from a field or external storage).
 * 4. Runs the AI analysis on the scan image.
 * 5. Inserts diagnostic results and recommendations into the database.
 * 6. Updates the scan and job records accordingly.
 *
 * This implementation leans on the structure from file 2 while using the AI analysis
 * pipeline from file 1.
 *
 * @param {string} scanId - ID of the scan to process.
 * @returns {Promise<Object>} - Final processing result.
 */
const processEyeScan = async (scanId) => {
  try {
    console.log(`Processing scan ${scanId}...`);
    
    // Retrieve the scan record from the 'eye_scans' table
    const scan = await knex('eye_scans').where({ id: scanId }).first();
    if (!scan) {
      throw new Error(`Scan not found: ${scanId}`);
    }
    
    // Mark processing as started: update processing_jobs (25% progress)
    await knex('processing_jobs')
      .where({ scan_id: scanId })
      .update({
        status: 'processing',
        progress: 25,
        updated_at: knex.fn.now()
      });
    
    // Retrieve the scan image.
    // For this example, we assume the scan record has an "image_path" field.
    let scanResult;
    if (typeof scan.image_path === 'string') {
      scanResult = { imageData: scan.image_path };
    } else {
      throw new Error(`Scan image path not found for scan: ${scanId}`);
    }
    
    // Analyze the retinal image using the AI pipeline
    const analysisResults = await analyzeRetinalImage(scanResult.imageData, { eyeSide: scan.eye_side });
    
    // Update processing progress to 75% after analysis
    await knex('processing_jobs')
      .where({ scan_id: scanId })
      .update({
        progress: 75,
        updated_at: knex.fn.now()
      });
    
    // Create and insert a diagnostic result record
    const resultId = uuidv4();
    await knex('diagnostic_results').insert({
      id: resultId,
      scan_id: scanId,
      condition: analysisResults.condition,
      confidence: analysisResults.confidence,
      severity: analysisResults.severity,
      diagnosis: analysisResults.diagnosis,
      processing_time: analysisResults.processingTime,
      ai_model_version: analysisResults.aiModelVersion,
      created_at: knex.fn.now(),
      updated_at: knex.fn.now()
    });
    
    // Insert recommendations (each with an increasing priority)
    for (let i = 0; i < analysisResults.recommendations.length; i++) {
      await knex('recommendations').insert({
        id: uuidv4(),
        result_id: resultId,
        recommendation: analysisResults.recommendations[i],
        priority: i + 1,
        created_at: knex.fn.now(),
        updated_at: knex.fn.now()
      });
    }
    
    // Update the eye scan record with the image quality metric
    await knex('eye_scans')
      .where({ id: scanId })
      .update({
        image_quality: analysisResults.imageQuality,
        updated_at: knex.fn.now()
      });
    
    // Finalize the processing job: mark as completed (100% progress)
    await knex('processing_jobs')
      .where({ scan_id: scanId })
      .update({
        status: 'completed',
        progress: 100,
        completed_at: knex.fn.now(),
        updated_at: knex.fn.now()
      });
    
    // Return a summary of the result
    return {
      id: resultId,
      scanId,
      ...analysisResults
    };
  } catch (error) {
    console.error(`Error processing scan ${scanId}:`, error);
    
    // On error, update the processing job to "failed"
    await knex('processing_jobs')
      .where({ scan_id: scanId })
      .update({
        status: 'failed',
        error_message: error.message,
        updated_at: knex.fn.now()
      });
    
    throw error;
  }
};

module.exports = {
  processEyeScan
};

const { v4: uuidv4 } = require('uuid');
const knex = require('../utils/db');

/**
 * Process an eye scan (mock implementation)
 * @param {string} scanId - ID of the scan to process
 * @returns {Promise<Object>} - Processing result
 */
const processEyeScan = async (scanId) => {
  try {
    // Get scan from database
    const scan = await knex('eye_scans')
      .where({ id: scanId })
      .first();
    
    if (!scan) {
      throw new Error(`Scan not found: ${scanId}`);
    }
    
    // Update job status to processing
    await knex('processing_jobs')
      .where({ scan_id: scanId })
      .update({
        status: 'processing',
        progress: 25,
        updated_at: knex.fn.now()
      });
    
    // Simulate processing time
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // Update progress
    await knex('processing_jobs')
      .where({ scan_id: scanId })
      .update({
        progress: 75,
        updated_at: knex.fn.now()
      });
    
    // Simulate more processing time
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Generate mock results based on eye side
    const mockConditions = [
      'normal', 'conjunctivitis', 'glaucoma', 'cataract'
    ];
    const mockSeverity = ['none', 'low', 'moderate', 'high'];
    
    const randomCondition = mockConditions[Math.floor(Math.random() * mockConditions.length)];
    const randomSeverity = mockSeverity[Math.floor(Math.random() * mockSeverity.length)];
    const randomConfidence = (Math.random() * 0.2 + 0.8).toFixed(2); // 0.80-0.99
    
    let diagnosis = '';
    switch (randomCondition) {
      case 'normal':
        diagnosis = 'No abnormalities detected in the eye scan.';
        break;
      case 'conjunctivitis':
        diagnosis = 'Signs of conjunctivitis detected, which is an inflammation of the conjunctiva.';
        break;
      case 'glaucoma':
        diagnosis = 'Potential indicators of glaucoma present, which may affect the optic nerve.';
        break;
      case 'cataract':
        diagnosis = 'Signs of cataract formation detected, causing clouding of the lens.';
        break;
      default:
        diagnosis = 'Analysis complete but results inconclusive.';
    }
    
    // Create diagnostic result
    const resultId = uuidv4();
    await knex('diagnostic_results').insert({
      id: resultId,
      scan_id: scanId,
      condition: randomCondition,
      confidence: parseFloat(randomConfidence),
      severity: randomSeverity,
      diagnosis,
      created_at: knex.fn.now(),
      updated_at: knex.fn.now()
    });
    
    // Update eye scan image quality
    const imageQuality = Math.floor(Math.random() * 30) + 70; // 70-99
    await knex('eye_scans')
      .where({ id: scanId })
      .update({
        image_quality: imageQuality,
        updated_at: knex.fn.now()
      });
    
    // Update job status to completed
    await knex('processing_jobs')
      .where({ scan_id: scanId })
      .update({
        status: 'completed',
        progress: 100,
        completed_at: knex.fn.now(),
        updated_at: knex.fn.now()
      });
    
    return {
      id: resultId,
      scanId,
      condition: randomCondition,
      confidence: parseFloat(randomConfidence),
      severity: randomSeverity,
      diagnosis
    };
  } catch (error) {
    console.error('Error processing eye scan:', error);
    
    // Update job status to failed
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
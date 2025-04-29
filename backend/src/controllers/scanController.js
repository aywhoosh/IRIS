const { v4: uuidv4 } = require('uuid');
const path = require('path');
const fs = require('fs').promises;
const knex = require('../utils/db');
const storageConfig = require('../config/storage');

const uploadScan = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image file provided'
      });
    }
    
    const { eyeSide } = req.body;
    
    if (!eyeSide || !['left', 'right'].includes(eyeSide)) {
      return res.status(400).json({
        success: false,
        message: 'Valid eye side (left/right) is required'
      });
    }
    
    // Generate unique filename and path
    const fileExtension = path.extname(req.file.originalname).toLowerCase();
    const filename = `${uuidv4()}${fileExtension}`;
    const relativePath = `${new Date().getFullYear()}/${filename}`;
    const fullPath = path.join(storageConfig.local.basePath, relativePath);
    
    // Ensure directory exists
    const dirPath = path.dirname(fullPath);
    await fs.mkdir(dirPath, { recursive: true });
    
    // Save the file
    await fs.writeFile(fullPath, req.file.buffer);
    
    // Create scan record
    const scanId = uuidv4();
    await knex('eye_scans').insert({
      id: scanId,
      user_id: req.user.id,
      image_path: relativePath,
      eye_side: eyeSide,
      created_at: knex.fn.now(),
      updated_at: knex.fn.now()
    });
    
    // Create processing job
    const jobId = uuidv4();
    await knex('processing_jobs').insert({
      id: jobId,
      scan_id: scanId,
      status: 'queued',
      progress: 0,
      created_at: knex.fn.now(),
      updated_at: knex.fn.now()
    });
    
    res.status(201).json({
      success: true,
      message: 'Eye scan uploaded successfully',
      data: {
        scanId,
        jobId
      }
    });
  } catch (error) {
    console.error('Error uploading eye scan:', error);
    res.status(500).json({
      success: false,
      message: 'Error uploading eye scan'
    });
  }
};

const getScans = async (req, res) => {
  try {
    const scans = await knex('eye_scans')
      .where({ user_id: req.user.id })
      .orderBy('created_at', 'desc')
      .select('*');
    
    res.status(200).json({
      success: true,
      data: scans.map(scan => ({
        id: scan.id,
        eyeSide: scan.eye_side,
        imageQuality: scan.image_quality,
        createdAt: scan.created_at
      }))
    });
  } catch (error) {
    console.error('Error getting eye scans:', error);
    res.status(500).json({
      success: false,
      message: 'Error retrieving eye scans'
    });
  }
};

const getScanDetails = async (req, res) => {
  try {
    const { id } = req.params;
    
    const scan = await knex('eye_scans')
      .where({ id, user_id: req.user.id })
      .first();
    
    if (!scan) {
      return res.status(404).json({
        success: false,
        message: 'Eye scan not found'
      });
    }
    
    // Get diagnostic result directly from the database
    const result = await knex('diagnostic_results')
      .where({ scan_id: scan.id })
      .first();
    
    // Get recommendations if result exists
    let recommendations = [];
    if (result) {
      recommendations = await knex('recommendations')
        .where({ result_id: result.id })
        .orderBy('priority', 'asc')
        .select('recommendation', 'priority');
    }
    
    const diagnostics = result ? {
      id: result.id,
      condition: result.condition,
      confidence: result.confidence,
      severity: result.severity,
      diagnosis: result.diagnosis,
      aiModelVersion: result.ai_model_version,
      verifiedByDoctor: result.verified_by_doctor,
      verificationDate: result.verification_date,
      createdAt: result.created_at
    } : null;
    
    res.status(200).json({
      success: true,
      data: {
        id: scan.id,
        eyeSide: scan.eye_side,
        imageQuality: scan.image_quality,
        createdAt: scan.created_at,
        processing: {
          status: result ? 'completed' : 'processing',
          progress: result ? 100 : 50
        },
        diagnostics,
        recommendations: recommendations.map(rec => rec.recommendation)
      }
    });
  } catch (error) {
    console.error('Error getting scan details:', error);
    res.status(500).json({
      success: false,
      message: 'Error retrieving scan details'
    });
  }
};

/**
 * Delete an eye scan and its associated data
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
const deleteScan = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Get scan to verify ownership
    const scan = await knex('eye_scans')
      .where({ id })
      .first();
    
    if (!scan) {
      return res.status(404).json({
        success: false,
        message: 'Eye scan not found'
      });
    }
    
    // Verify user owns the scan or is a doctor
    if (scan.patient_id !== req.user.id) {
      const userRole = await knex('users')
        .where({ id: req.user.id })
        .first('role');
      
      if (!userRole || userRole.role !== 'doctor') {
        return res.status(403).json({
          success: false,
          message: 'Not authorized to delete this scan'
        });
      }
    }
    
    // Start a transaction to ensure all related data is deleted consistently
    await knex.transaction(async (trx) => {
      // Get diagnostic result ID to delete recommendations
      const diagnosticResult = await trx('diagnostic_results')
        .where({ scan_id: id })
        .first('id');
      
      // Delete recommendations if diagnostic result exists
      if (diagnosticResult) {
        await trx('recommendations')
          .where({ result_id: diagnosticResult.id })
          .del();
      }
      
      // Delete diagnostic result
      await trx('diagnostic_results')
        .where({ scan_id: id })
        .del();
      
      // Delete processing jobs
      await trx('processing_jobs')
        .where({ scan_id: id })
        .del();
      
      // Delete the scan itself
      await trx('eye_scans')
        .where({ id })
        .del();
    });
    
    // Log the deletion
    await knex('audit_logs').insert({
      id: uuidv4(),
      user_id: req.user.id,
      action: 'delete',
      resource_type: 'eye_scan',
      resource_id: id,
      ip_address: req.ip,
      user_agent: req.headers['user-agent'],
      created_at: knex.fn.now()
    });
    
    res.status(200).json({
      success: true,
      message: 'Eye scan and associated data deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting eye scan:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting eye scan',
      error: error.message
    });
  }
};

module.exports = {
  uploadScan,
  getScans,
  getScanDetails,
  deleteScan
};
/**
 * Results controller for the IRIS backend
 * Handles diagnostic results and recommendations
 */
const { v4: uuidv4 } = require('uuid');
const knex = require('../config/knex');

/**
 * Get diagnostic result for a scan
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
const getDiagnosticResult = async (req, res) => {
  try {
    const { scanId } = req.params;
    
    // Get scan to check access
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
    
    // Get diagnostic result
    const diagnosticResult = await knex('diagnostic_results')
      .where({ scan_id: scanId })
      .first();
    
    if (!diagnosticResult) {
      return res.status(404).json({
        success: false,
        message: 'Diagnostic result not found for this scan'
      });
    }
    
    // Get recommendations
    const recommendations = await knex('recommendations')
      .where({ result_id: diagnosticResult.id })
      .orderBy('priority', 'asc')
      .select('id', 'recommendation', 'priority');
    
    // Log audit event
    await knex('audit_logs').insert({
      id: uuidv4(),
      user_id: req.user.id,
      action: 'view',
      resource_type: 'diagnostic_result',
      resource_id: diagnosticResult.id,
      ip_address: req.ip,
      user_agent: req.headers['user-agent'],
      created_at: knex.fn.now()
    });
    
    // Return result
    res.status(200).json({
      success: true,
      data: {
        id: diagnosticResult.id,
        scanId: diagnosticResult.scan_id,
        condition: diagnosticResult.condition,
        confidence: diagnosticResult.confidence,
        severity: diagnosticResult.severity,
        diagnosis: diagnosticResult.diagnosis,
        processingTime: diagnosticResult.processing_time,
        aiModelVersion: diagnosticResult.ai_model_version,
        verifiedByDoctor: diagnosticResult.verified_by_doctor,
        verificationDate: diagnosticResult.verification_date,
        createdAt: diagnosticResult.created_at,
        updatedAt: diagnosticResult.updated_at,
        recommendations: recommendations.map(rec => ({
          id: rec.id,
          recommendation: rec.recommendation,
          priority: rec.priority
        }))
      }
    });
  } catch (error) {
    console.error('Error getting diagnostic result:', error);
    
    res.status(500).json({
      success: false,
      message: 'Error getting diagnostic result',
      error: error.message
    });
  }
};

/**
 * Get all diagnostic results for a user
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
const getUserDiagnosticResults = async (req, res) => {
  try {
    const { userId } = req.params;
    const { condition, limit = 10, offset = 0 } = req.query;
    
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
    
    // Get scans for this user
    const scans = await knex('eye_scans')
      .where({ patient_id: userId })
      .whereNull('deleted_at')
      .select('id');
    
    const scanIds = scans.map(scan => scan.id);
    
    if (scanIds.length === 0) {
      return res.status(200).json({
        success: true,
        data: {
          results: [],
          pagination: {
            total: 0,
            limit: parseInt(limit, 10),
            offset: parseInt(offset, 10),
            hasMore: false
          }
        }
      });
    }
    
    // Build query for diagnostic results
    const resultsQuery = knex('diagnostic_results')
      .whereIn('scan_id', scanIds)
      .orderBy('created_at', 'desc')
      .limit(parseInt(limit, 10))
      .offset(parseInt(offset, 10));
    
    // Filter by condition if provided
    if (condition) {
      resultsQuery.where({ condition });
    }
    
    // Get results
    const results = await resultsQuery;
    
    // Get total count
    const countQuery = knex('diagnostic_results')
      .whereIn('scan_id', scanIds)
      .count('id as total');
    
    if (condition) {
      countQuery.where({ condition });
    }
    
    const [{ total }] = await countQuery;
    
    // Get scan details for each result
    const resultIds = results.map(result => result.id);
    
    // Get recommendations for all results
    const recommendations = resultIds.length > 0
      ? await knex('recommendations')
          .whereIn('result_id', resultIds)
          .select('id', 'result_id', 'recommendation', 'priority')
      : [];
    
    // Create a map of result_id to recommendations
    const recommendationsMap = {};
    recommendations.forEach(rec => {
      if (!recommendationsMap[rec.result_id]) {
        recommendationsMap[rec.result_id] = [];
      }
      recommendationsMap[rec.result_id].push({
        id: rec.id,
        recommendation: rec.recommendation,
        priority: rec.priority
      });
    });
    
    // Get scan details
    const scanDetailsMap = {};
    if (results.length > 0) {
      const scanDetails = await knex('eye_scans')
        .whereIn('id', results.map(r => r.scan_id))
        .select('id', 'eye_side', 'scan_date');
      
      scanDetails.forEach(scan => {
        scanDetailsMap[scan.id] = scan;
      });
    }
    
    // Log audit event
    await knex('audit_logs').insert({
      id: uuidv4(),
      user_id: req.user.id,
      action: 'list',
      resource_type: 'diagnostic_results',
      details: JSON.stringify({
        patient_id: userId,
        count: results.length
      }),
      ip_address: req.ip,
      user_agent: req.headers['user-agent'],
      created_at: knex.fn.now()
    });
    
    // Return results
    res.status(200).json({
      success: true,
      data: {
        results: results.map(result => ({
          id: result.id,
          scanId: result.scan_id,
          eyeSide: scanDetailsMap[result.scan_id]?.eye_side,
          scanDate: scanDetailsMap[result.scan_id]?.scan_date,
          condition: result.condition,
          confidence: result.confidence,
          severity: result.severity,
          diagnosis: result.diagnosis,
          aiModelVersion: result.ai_model_version,
          verifiedByDoctor: result.verified_by_doctor,
          createdAt: result.created_at,
          recommendations: recommendationsMap[result.id] || []
        })),
        pagination: {
          total: parseInt(total, 10),
          limit: parseInt(limit, 10),
          offset: parseInt(offset, 10),
          hasMore: parseInt(offset, 10) + results.length < parseInt(total, 10)
        }
      }
    });
  } catch (error) {
    console.error('Error getting user diagnostic results:', error);
    
    res.status(500).json({
      success: false,
      message: 'Error getting user diagnostic results',
      error: error.message
    });
  }
};

/**
 * Verify a diagnostic result (doctor only)
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
const verifyDiagnosticResult = async (req, res) => {
  try {
    const { resultId } = req.params;
    const { verified, notes } = req.body;
    
    // Check if user is a doctor
    if (req.user.role !== 'doctor') {
      return res.status(403).json({
        success: false,
        message: 'Only doctors can verify diagnostic results'
      });
    }
    
    // Get diagnostic result
    const diagnosticResult = await knex('diagnostic_results')
      .where({ id: resultId })
      .first();
    
    if (!diagnosticResult) {
      return res.status(404).json({
        success: false,
        message: 'Diagnostic result not found'
      });
    }
    
    // Update diagnostic result
    await knex('diagnostic_results')
      .where({ id: resultId })
      .update({
        verified_by_doctor: verified ? req.user.id : null,
        verification_date: verified ? knex.fn.now() : null,
        updated_at: knex.fn.now()
      });
    
    // Log audit event
    await knex('audit_logs').insert({
      id: uuidv4(),
      user_id: req.user.id,
      action: verified ? 'verify' : 'unverify',
      resource_type: 'diagnostic_result',
      resource_id: resultId,
      details: JSON.stringify({
        notes
      }),
      ip_address: req.ip,
      user_agent: req.headers['user-agent'],
      created_at: knex.fn.now()
    });
    
    // Return success
    res.status(200).json({
      success: true,
      message: `Diagnostic result ${verified ? 'verified' : 'unverified'} successfully`,
      data: {
        resultId,
        verified,
        verifiedBy: verified ? req.user.id : null,
        verificationDate: verified ? new Date().toISOString() : null
      }
    });
  } catch (error) {
    console.error('Error verifying diagnostic result:', error);
    
    res.status(500).json({
      success: false,
      message: 'Error verifying diagnostic result',
      error: error.message
    });
  }
};

/**
 * Generate a shareable report for a diagnostic result
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
const generateShareableReport = async (req, res) => {
  try {
    const { resultId } = req.params;
    
    // Get diagnostic result
    const diagnosticResult = await knex('diagnostic_results')
      .where({ id: resultId })
      .first();
    
    if (!diagnosticResult) {
      return res.status(404).json({
        success: false,
        message: 'Diagnostic result not found'
      });
    }
    
    // Get scan to check access
    const scan = await knex('eye_scans')
      .where({ id: diagnosticResult.scan_id })
      .first();
    
    // Check if user has access to this result
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
    
    // Get recommendations
    const recommendations = await knex('recommendations')
      .where({ result_id: diagnosticResult.id })
      .orderBy('priority', 'asc')
      .select('recommendation');
    
    // Get patient details
    const patient = await knex('users')
      .where({ id: scan.patient_id })
      .first('first_name', 'last_name', 'date_of_birth');
    
    // Generate a unique token for the report
    const reportToken = uuidv4();
    
    // Store report token in database (in a real implementation)
    // This would be stored in a reports table with an expiry date
    
    // Log audit event
    await knex('audit_logs').insert({
      id: uuidv4(),
      user_id: req.user.id,
      action: 'generate_report',
      resource_type: 'diagnostic_result',
      resource_id: resultId,
      ip_address: req.ip,
      user_agent: req.headers['user-agent'],
      created_at: knex.fn.now()
    });
    
    // Return report data
    res.status(200).json({
      success: true,
      message: 'Shareable report generated successfully',
      data: {
        reportUrl: `/api/results/report/${reportToken}`,
        reportToken,
        expiresIn: '7 days', // In a real implementation, this would be configurable
        reportData: {
          patientName: `${patient.first_name} ${patient.last_name}`,
          patientDob: patient.date_of_birth,
          scanDate: scan.scan_date,
          eyeSide: scan.eye_side,
          condition: diagnosticResult.condition,
          confidence: diagnosticResult.confidence,
          severity: diagnosticResult.severity,
          diagnosis: diagnosticResult.diagnosis,
          recommendations: recommendations.map(rec => rec.recommendation),
          aiModelVersion: diagnosticResult.ai_model_version,
          verifiedByDoctor: diagnosticResult.verified_by_doctor ? true : false,
          generatedAt: new Date().toISOString()
        }
      }
    });
  } catch (error) {
    console.error('Error generating shareable report:', error);
    
    res.status(500).json({
      success: false,
      message: 'Error generating shareable report',
      error: error.message
    });
  }
};

/**
 * Get a shareable report by token
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
const getShareableReport = async (req, res) => {
  try {
    const { token } = req.params;
    
    // In a real implementation, validate the token against the database
    // Check if token exists and is not expired
    
    // For demo purposes, return a mock report
    res.status(200).json({
      success: true,
      data: {
        reportToken: token,
        patientName: 'John Doe',
        patientDob: '1980-01-01',
        scanDate: '2025-04-01T10:30:00Z',
        eyeSide: 'right',
        condition: 'glaucoma',
        confidence: 0.92,
        severity: 'moderate',
        diagnosis: 'Potential indicators of glaucoma present. Glaucoma is caused by increased pressure in the eye damaging the optic nerve.',
        recommendations: [
          'Schedule an appointment with an ophthalmologist immediately',
          'This condition requires professional monitoring and treatment',
          'Early treatment can prevent vision loss',
          'Adherence to prescribed eye drops is crucial if diagnosed'
        ],
        aiModelVersion: '2.0.0',
        verifiedByDoctor: true,
        generatedAt: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Error retrieving shareable report:', error);
    
    res.status(500).json({
      success: false,
      message: 'Error retrieving shareable report',
      error: error.message
    });
  }
};

module.exports = {
  getDiagnosticResult,
  getUserDiagnosticResults,
  verifyDiagnosticResult,
  generateShareableReport,
  getShareableReport
};

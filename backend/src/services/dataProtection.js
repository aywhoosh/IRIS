/**
 * Data protection service for HIPAA compliance
 */
const { v4: uuidv4 } = require('uuid');
const knex = require('../utils/db');
const encryption = require('../utils/encryption');

/**
 * Encrypt sensitive data for storage
 * @param {Object} data - Data to encrypt
 * @param {Array} sensitiveFields - Fields to encrypt
 * @returns {Object} - Data with encrypted fields
 */
const encryptSensitiveData = (data, sensitiveFields) => {
  if (!data) return data;
  
  const encryptedData = { ...data };
  
  sensitiveFields.forEach(field => {
    if (encryptedData[field]) {
      const encrypted = encryption.encrypt(encryptedData[field].toString());
      encryptedData[field] = encrypted;
    }
  });
  
  return encryptedData;
};

/**
 * Decrypt sensitive data
 * @param {Object} data - Data with encrypted fields
 * @param {Array} sensitiveFields - Fields that are encrypted
 * @returns {Object} - Data with decrypted fields
 */
const decryptSensitiveData = (data, sensitiveFields) => {
  if (!data) return data;
  
  const decryptedData = { ...data };
  
  sensitiveFields.forEach(field => {
    if (decryptedData[field] && typeof decryptedData[field] === 'object') {
      try {
        const decrypted = encryption.decrypt(decryptedData[field]);
        decryptedData[field] = decrypted.toString();
      } catch (error) {
        console.error(`Error decrypting field ${field}:`, error);
      }
    }
  });
  
  return decryptedData;
};

/**
 * Anonymize patient data for research
 * @param {Object} data - Patient data
 * @returns {Object} - Anonymized data
 */
const anonymizePatientData = (data) => {
  const anonymizedData = { ...data };
  
  // Remove direct identifiers
  delete anonymizedData.first_name;
  delete anonymizedData.last_name;
  delete anonymizedData.email;
  delete anonymizedData.phone_number;
  delete anonymizedData.date_of_birth;
  delete anonymizedData.medical_record_number;
  delete anonymizedData.insurance_policy_number;
  delete anonymizedData.profile_image_url;
  
  // Hash any remaining identifiers
  if (anonymizedData.emergency_contact_name) {
    anonymizedData.emergency_contact_name = hashIdentifier(anonymizedData.emergency_contact_name);
  }
  
  if (anonymizedData.emergency_contact_phone) {
    anonymizedData.emergency_contact_phone = hashIdentifier(anonymizedData.emergency_contact_phone);
  }
  
  // Generalize dates to month/year only
  if (anonymizedData.created_at) {
    anonymizedData.created_at = generalizeDate(anonymizedData.created_at);
  }
  
  if (anonymizedData.updated_at) {
    anonymizedData.updated_at = generalizeDate(anonymizedData.updated_at);
  }
  
  if (anonymizedData.scan_date) {
    anonymizedData.scan_date = generalizeDate(anonymizedData.scan_date);
  }
  
  return anonymizedData;
};

/**
 * Hash an identifier in a non-reversible way
 * @param {string} identifier - Identifier to hash
 * @returns {string} - Hashed identifier
 */
const hashIdentifier = (identifier) => {
  return encryption.hash(identifier);
};

/**
 * Generalize a date to month/year only
 * @param {Date|string} date - Date to generalize
 * @returns {string} - Generalized date (YYYY-MM)
 */
const generalizeDate = (date) => {
  const dateObj = new Date(date);
  return `${dateObj.getFullYear()}-${String(dateObj.getMonth() + 1).padStart(2, '0')}`;
};

/**
 * Check if access to a resource is authorized
 * @param {string} userId - User ID
 * @param {string} resourceType - Type of resource
 * @param {string} resourceId - ID of resource
 * @returns {Promise<boolean>} - Whether access is authorized
 */
const isAccessAuthorized = async (userId, resourceType, resourceId) => {
  try {
    if (!userId || !resourceType || !resourceId) {
      return false;
    }
    
    // Get user role
    const user = await knex('users')
      .where({ id: userId })
      .first('role');
    
    if (!user) {
      return false;
    }
    
    // Admin has access to everything
    if (user.role === 'admin') {
      return true;
    }
    
    switch (resourceType) {
      case 'user':
        // Users can access their own data
        return userId === resourceId;
      
      case 'eye_scan':
        // Patients can access their own scans, doctors can access all scans
        if (user.role === 'doctor') {
          return true;
        }
        
        const scan = await knex('eye_scans')
          .where({ id: resourceId })
          .first('patient_id');
        
        return scan && scan.patient_id === userId;
      
      case 'diagnostic_result':
        // Check if the result belongs to the user's scan
        const scanFromResult = await knex('diagnostic_results')
          .join('eye_scans', 'diagnostic_results.scan_id', 'eye_scans.id')
          .where('diagnostic_results.id', resourceId)
          .first('eye_scans.patient_id');
        
        return scanFromResult && scanFromResult.patient_id === userId;
      
      case 'patient_data':
        // Only the patient or doctors can access patient data
        if (user.role === 'doctor') {
          return true;
        }
        
        const targetUser = await knex('users')
          .where({ id: resourceId })
          .first('role');
        
        return targetUser && targetUser.role === 'patient';
      
      default:
        return false;
    }
  } catch (error) {
    console.error('Error checking access authorization:', error);
    return false;
  }
};

/**
 * Log data access for audit trail
 * @param {string} userId - User ID
 * @param {string} action - Action performed
 * @param {string} resourceType - Type of resource accessed
 * @param {string} resourceId - ID of resource accessed
 * @param {Object} details - Additional details
 * @param {string} ipAddress - IP address of user
 * @param {string} userAgent - User agent of user
 * @returns {Promise<string>} - Audit log ID
 */
const logDataAccess = async (userId, action, resourceType, resourceId, details, ipAddress, userAgent) => {
  try {
    const logId = uuidv4();
    
    await knex('audit_logs').insert({
      id: logId,
      user_id: userId,
      action,
      resource_type: resourceType,
      resource_id: resourceId,
      details: JSON.stringify(details),
      ip_address: ipAddress,
      user_agent: userAgent,
      created_at: knex.fn.now()
    });
    
    return logId;
  } catch (error) {
    console.error('Error logging data access:', error);
    throw error;
  }
};

/**
 * Generate a data export for patient
 * @param {string} patientId - Patient ID
 * @returns {Promise<Object>} - Data export
 */
const generatePatientDataExport = async (patientId) => {
  try {
    // Get patient data
    const patient = await knex('users')
      .where({ id: patientId })
      .first('id', 'email', 'first_name', 'last_name', 'date_of_birth', 'phone_number', 'created_at');
    
    if (!patient) {
      throw new Error(`Patient not found: ${patientId}`);
    }
    
    // Get patient-specific data
    const patientData = await knex('patients')
      .where({ id: patientId })
      .first();
    
    // Get eye scans
    const scans = await knex('eye_scans')
      .where({ patient_id: patientId })
      .select('id', 'scan_date', 'eye_side', 'image_quality', 'notes', 'created_at');
    
    // Get diagnostic results
    const scanIds = scans.map(scan => scan.id);
    const diagnosticResults = scanIds.length > 0
      ? await knex('diagnostic_results')
          .whereIn('scan_id', scanIds)
          .select('id', 'scan_id', 'condition', 'confidence', 'severity', 'diagnosis', 'created_at')
      : [];
    
    // Get recommendations
    const resultIds = diagnosticResults.map(result => result.id);
    const recommendations = resultIds.length > 0
      ? await knex('recommendations')
          .whereIn('result_id', resultIds)
          .select('id', 'result_id', 'recommendation', 'priority')
      : [];
    
    // Create export object
    const dataExport = {
      patient: {
        id: patient.id,
        email: patient.email,
        firstName: patient.first_name,
        lastName: patient.last_name,
        dateOfBirth: patient.date_of_birth,
        phoneNumber: patient.phone_number,
        createdAt: patient.created_at,
        ...patientData
      },
      scans: scans.map(scan => {
        const scanResults = diagnosticResults.filter(result => result.scan_id === scan.id);
        
        return {
          id: scan.id,
          scanDate: scan.scan_date,
          eyeSide: scan.eye_side,
          imageQuality: scan.image_quality,
          notes: scan.notes,
          createdAt: scan.created_at,
          results: scanResults.map(result => {
            const resultRecommendations = recommendations.filter(rec => rec.result_id === result.id);
            
            return {
              id: result.id,
              condition: result.condition,
              confidence: result.confidence,
              severity: result.severity,
              diagnosis: result.diagnosis,
              createdAt: result.created_at,
              recommendations: resultRecommendations.map(rec => ({
                recommendation: rec.recommendation,
                priority: rec.priority
              }))
            };
          })
        };
      }),
      exportDate: new Date().toISOString(),
      exportId: uuidv4()
    };
    
    return dataExport;
  } catch (error) {
    console.error('Error generating patient data export:', error);
    throw error;
  }
};

/**
 * Apply data retention policy
 * @param {number} retentionDays - Number of days to retain data
 * @returns {Promise<Object>} - Deletion results
 */
const applyDataRetentionPolicy = async (retentionDays = 2555) => { // Default 7 years (HIPAA)
  try {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - retentionDays);
    
    // Get scans older than retention period
    const oldScans = await knex('eye_scans')
      .where('created_at', '<', cutoffDate)
      .select('id');
    
    const scanIds = oldScans.map(scan => scan.id);
    
    if (scanIds.length === 0) {
      return {
        scansDeleted: 0,
        resultsDeleted: 0,
        recommendationsDeleted: 0
      };
    }
    
    // Get diagnostic results for these scans
    const oldResults = await knex('diagnostic_results')
      .whereIn('scan_id', scanIds)
      .select('id');
    
    const resultIds = oldResults.map(result => result.id);
    
    // Delete recommendations
    let recommendationsDeleted = 0;
    if (resultIds.length > 0) {
      recommendationsDeleted = await knex('recommendations')
        .whereIn('result_id', resultIds)
        .del();
    }
    
    // Delete diagnostic results
    const resultsDeleted = await knex('diagnostic_results')
      .whereIn('scan_id', scanIds)
      .del();
    
    // Delete scans
    const scansDeleted = await knex('eye_scans')
      .whereIn('id', scanIds)
      .del();
    
    return {
      scansDeleted,
      resultsDeleted,
      recommendationsDeleted
    };
  } catch (error) {
    console.error('Error applying data retention policy:', error);
    throw error;
  }
};

module.exports = {
  encryptSensitiveData,
  decryptSensitiveData,
  anonymizePatientData,
  logDataAccess,
  isAccessAuthorized,
  generatePatientDataExport,
  applyDataRetentionPolicy
};

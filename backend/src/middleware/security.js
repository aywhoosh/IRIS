/**
 * Security middleware for protecting API endpoints
 */
const crypto = require('crypto');
const knex = require('../utils/db');
const encryption = require('../utils/encryption');

/**
 * Add security headers to responses
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 * @param {Function} next - Express next
 */
const securityHeaders = (req, res, next) => {
  // Set security headers
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  res.setHeader('Content-Security-Policy', "default-src 'self'");
  res.setHeader('Referrer-Policy', 'same-origin');
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');
  res.setHeader('Surrogate-Control', 'no-store');
  
  next();
};

/**
 * Log data access for audit and compliance
 * @param {string} userId - User ID
 * @param {string} action - Action performed
 * @param {string} resourceType - Type of resource accessed
 * @param {string} resourceId - ID of resource accessed
 * @param {Object} details - Additional details
 * @param {string} ipAddress - IP address of user
 * @param {string} userAgent - User agent of user
 * @returns {Promise<string>} - Audit log ID
 */
const auditLog = async (userId, action, resourceType, resourceId, details, ipAddress, userAgent) => {
  const logId = crypto.randomUUID();
  
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
};

/**
 * Anonymize sensitive patient data for privacy
 * @param {Object} data - Patient data
 * @returns {Object} - Anonymized data
 */
const anonymizeData = (data) => {
  const anonymizedData = { ...data };
  
  // Remove direct identifiers
  delete anonymizedData.first_name;
  delete anonymizedData.last_name;
  delete anonymizedData.email;
  delete anonymizedData.phone_number;
  delete anonymizedData.date_of_birth;
  delete anonymizedData.profile_image_url;
  
  // Hash any remaining identifiers
  if (anonymizedData.emergency_contact_name) {
    anonymizedData.emergency_contact_name = encryption.hash(anonymizedData.emergency_contact_name);
  }
  
  if (anonymizedData.emergency_contact_phone) {
    anonymizedData.emergency_contact_phone = encryption.hash(anonymizedData.emergency_contact_phone);
  }
  
  // Generalize dates
  if (anonymizedData.created_at) {
    const date = new Date(anonymizedData.created_at);
    anonymizedData.created_at = `${date.getFullYear()}-${date.getMonth() + 1}`;
  }
  
  return anonymizedData;
};

/**
 * Validate request against a schema
 * @param {Object} schema - Validation schema
 * @returns {Function} - Express middleware
 */
const validateRequest = (schema) => {
  return (req, res, next) => {
    try {
      const { error } = schema.validate(req.body);
      if (error) {
        return res.status(400).json({
          success: false,
          message: 'Validation error',
          errors: error.details.map(d => d.message)
        });
      }
      next();
    } catch (error) {
      next(error);
    }
  };
};

/**
 * Generate a secure token for sensitive operations
 * @param {number} length - Token length (default: 32)
 * @returns {string} - Secure random token
 */
const generateSecureToken = (length = 32) => {
  return crypto.randomBytes(length).toString('hex');
};

/**
 * Hash sensitive data for secure storage
 * @param {string} data - Data to hash
 * @returns {string} - Hashed data
 */
const hashData = (data) => {
  return encryption.hash(data);
};

/**
 * Encrypt sensitive data
 * @param {string|Buffer} data - Data to encrypt
 * @returns {Object} - Encrypted data
 */
const encryptData = (data) => {
  return encryption.encrypt(data);
};

/**
 * Decrypt sensitive data
 * @param {Object} encryptedData - Encrypted data object
 * @returns {Buffer} - Decrypted data
 */
const decryptData = (encryptedData) => {
  return encryption.decrypt(encryptedData);
};

module.exports = {
  securityHeaders,
  auditLog,
  anonymizeData,
  validateRequest,
  generateSecureToken,
  hashData,
  encryptData,
  decryptData
};

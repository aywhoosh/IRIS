/**
 * JWT token generation and validation utilities
 */
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const authConfig = require('../config/auth');
const knex = require('./db');

/**
 * Generate an access token
 * @param {Object} user - User object
 * @returns {string} - JWT token
 */
const generateAccessToken = (user) => {
  const payload = {
    sub: user.id,
    email: user.email,
    firstName: user.first_name,
    lastName: user.last_name,
    role: user.role,
    jti: uuidv4()
  };

  return jwt.sign(payload, authConfig.jwt.secret, {
    expiresIn: authConfig.jwt.expiration,
    algorithm: authConfig.jwt.algorithm,
    issuer: authConfig.jwt.issuer,
    audience: authConfig.jwt.audience
  });
};

/**
 * Generate a refresh token
 * @param {Object} user - User object
 * @returns {Object} - Token object with value and expiry
 */
const generateRefreshToken = async (user) => {
  const jti = uuidv4();
  
  // Calculate expiry date
  const expiresIn = authConfig.jwt.refreshExpiration;
  const expiryDate = new Date();
  
  // Convert string like '7d' to milliseconds
  let ms = 0;
  if (typeof expiresIn === 'string') {
    const match = expiresIn.match(/^(\d+)([smhdw])$/);
    if (match) {
      const val = parseInt(match[1], 10);
      const unit = match[2];
      switch (unit) {
        case 's': ms = val * 1000; break;
        case 'm': ms = val * 60 * 1000; break;
        case 'h': ms = val * 60 * 60 * 1000; break;
        case 'd': ms = val * 24 * 60 * 60 * 1000; break;
        case 'w': ms = val * 7 * 24 * 60 * 60 * 1000; break;
      }
    }
  } else if (typeof expiresIn === 'number') {
    ms = expiresIn * 1000;
  }
  
  expiryDate.setTime(expiryDate.getTime() + ms);
  
  // Create token payload
  const payload = {
    sub: user.id,
    jti
  };
  
  // Generate token
  const token = jwt.sign(payload, authConfig.jwt.refreshSecret, {
    expiresIn,
    algorithm: authConfig.jwt.algorithm,
    issuer: authConfig.jwt.issuer,
    audience: authConfig.jwt.audience
  });
  
  // Store refresh token in database
  await knex('refresh_tokens').insert({
    id: uuidv4(),
    user_id: user.id,
    token: jti,
    expires_at: expiryDate,
    created_at: knex.fn.now()
  });
  
  return {
    token,
    expiresAt: expiryDate
  };
};

/**
 * Validate an access token
 * @param {string} token - JWT token
 * @returns {Object} - Decoded token payload
 * @throws {Error} - If token is invalid
 */
const validateAccessToken = (token) => {
  try {
    return jwt.verify(token, authConfig.jwt.secret, {
      issuer: authConfig.jwt.issuer,
      audience: authConfig.jwt.audience
    });
  } catch (error) {
    throw new Error('Invalid or expired token');
  }
};

/**
 * Validate a refresh token
 * @param {string} token - JWT token
 * @returns {Object} - Decoded token payload
 * @throws {Error} - If token is invalid
 */
const validateRefreshToken = async (token) => {
  try {
    // Verify token signature
    const decoded = jwt.verify(token, authConfig.jwt.refreshSecret, {
      issuer: authConfig.jwt.issuer,
      audience: authConfig.jwt.audience
    });
    
    // Check if token exists in database and isn't revoked
    const storedToken = await knex('refresh_tokens')
      .where({
        token: decoded.jti,
        user_id: decoded.sub
      })
      .where('expires_at', '>', knex.fn.now())
      .where(function() {
        this.where('revoked', false).orWhereNull('revoked');
      })
      .first();
    
    if (!storedToken) {
      throw new Error('Invalid refresh token');
    }
    
    return decoded;
  } catch (error) {
    throw new Error('Invalid or expired refresh token');
  }
};

/**
 * Revoke a refresh token
 * @param {string} token - JWT token
 * @returns {boolean} - Success indicator
 */
const revokeRefreshToken = async (token) => {
  try {
    // Verify token signature
    const decoded = jwt.verify(token, authConfig.jwt.refreshSecret, {
      issuer: authConfig.jwt.issuer,
      audience: authConfig.jwt.audience
    });
    
    // Update token in database
    await knex('refresh_tokens')
      .where({ token: decoded.jti })
      .update({
        revoked: true,
        revoked_at: knex.fn.now()
      });
    
    return true;
  } catch (error) {
    return false;
  }
};

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  validateAccessToken,
  validateRefreshToken,
  revokeRefreshToken
};

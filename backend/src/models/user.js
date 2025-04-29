/**
 * User model for the IRIS backend
 */
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcrypt');
const knex = require('../config/knex');
const authConfig = require('../config/auth');

class User {
  /**
   * Create a new user
   * @param {Object} userData - User data
   * @returns {Promise<Object>} - Created user object
   */
  static async create(userData) {
    const { password, ...userInfo } = userData;
    
    // Validate password
    this.validatePassword(password);
    
    // Hash password
    const passwordHash = await bcrypt.hash(password, authConfig.password.saltRounds);
    
    // Generate UUID for new user
    const userId = uuidv4();
    
    // Create user record
    const [user] = await knex('users')
      .insert({
        id: userId,
        ...userInfo,
        password_hash: passwordHash,
        created_at: knex.fn.now(),
        updated_at: knex.fn.now()
      })
      .returning(['id', 'email', 'first_name', 'last_name', 'role', 'created_at', 'email_verified']);
    
    return user;
  }
  
  /**
   * Find user by ID
   * @param {string} id - User ID
   * @returns {Promise<Object|null>} - User object or null if not found
   */
  static async findById(id) {
    const user = await knex('users')
      .where({ id })
      .first('id', 'email', 'first_name', 'last_name', 'role', 'created_at', 'updated_at', 'last_login', 'account_status', 'email_verified', 'profile_image_url');
    
    return user || null;
  }
  
  /**
   * Find user by email
   * @param {string} email - User email
   * @returns {Promise<Object|null>} - User object or null if not found
   */
  static async findByEmail(email) {
    const user = await knex('users')
      .where({ email })
      .first('id', 'email', 'password_hash', 'first_name', 'last_name', 'role', 'created_at', 'updated_at', 'last_login', 'account_status', 'email_verified', 'profile_image_url');
    
    return user || null;
  }
  
  /**
   * Update user
   * @param {string} id - User ID
   * @param {Object} userData - User data to update
   * @returns {Promise<Object>} - Updated user object
   */
  static async update(id, userData) {
    const { password, ...updateData } = userData;
    
    // If password is provided, hash it
    if (password) {
      this.validatePassword(password);
      updateData.password_hash = await bcrypt.hash(password, authConfig.password.saltRounds);
    }
    
    // Update user record
    const [user] = await knex('users')
      .where({ id })
      .update({
        ...updateData,
        updated_at: knex.fn.now()
      })
      .returning(['id', 'email', 'first_name', 'last_name', 'role', 'created_at', 'updated_at', 'account_status', 'email_verified', 'profile_image_url']);
    
    return user;
  }
  
  /**
   * Delete user
   * @param {string} id - User ID
   * @returns {Promise<boolean>} - True if user was deleted
   */
  static async delete(id) {
    const deleted = await knex('users')
      .where({ id })
      .del();
    
    return deleted > 0;
  }
  
  /**
   * Verify user password
   * @param {string} id - User ID
   * @param {string} password - Password to verify
   * @returns {Promise<boolean>} - True if password is correct
   */
  static async verifyPassword(id, password) {
    const user = await knex('users')
      .where({ id })
      .first('password_hash');
    
    if (!user) return false;
    
    return bcrypt.compare(password, user.password_hash);
  }
  
  /**
   * Update last login timestamp
   * @param {string} id - User ID
   * @returns {Promise<void>}
   */
  static async updateLastLogin(id) {
    await knex('users')
      .where({ id })
      .update({
        last_login: knex.fn.now()
      });
  }
  
  /**
   * Validate password against requirements
   * @param {string} password - Password to validate
   * @throws {Error} - If password does not meet requirements
   */
  static validatePassword(password) {
    const { minLength, requireUppercase, requireLowercase, requireNumbers, requireSymbols } = authConfig.password;
    
    if (!password || password.length < minLength) {
      throw new Error(`Password must be at least ${minLength} characters long`);
    }
    
    if (requireUppercase && !/[A-Z]/.test(password)) {
      throw new Error('Password must contain at least one uppercase letter');
    }
    
    if (requireLowercase && !/[a-z]/.test(password)) {
      throw new Error('Password must contain at least one lowercase letter');
    }
    
    if (requireNumbers && !/[0-9]/.test(password)) {
      throw new Error('Password must contain at least one number');
    }
    
    if (requireSymbols && !/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)) {
      throw new Error('Password must contain at least one special character');
    }
  }
  
  /**
   * Get user with role-specific data
   * @param {string} id - User ID
   * @returns {Promise<Object>} - User object with role-specific data
   */
  static async getWithRoleData(id) {
    const user = await this.findById(id);
    
    if (!user) return null;
    
    // Get role-specific data
    if (user.role === 'patient') {
      const patientData = await knex('patients')
        .where({ id: user.id })
        .first();
      
      if (patientData) {
        user.patientData = patientData;
      }
    } else if (user.role === 'doctor') {
      const doctorData = await knex('doctors')
        .where({ id: user.id })
        .first();
      
      if (doctorData) {
        user.doctorData = doctorData;
      }
    }
    
    return user;
  }
}

module.exports = User;

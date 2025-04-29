const express = require('express');
const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');
const jwt = require('../utils/jwt');
const knex = require('../utils/db');
const { authLimiter } = require('../middleware/rateLimiter');
const { authenticate } = require('../middleware/auth');
const authConfig = require('../config/auth');

const router = express.Router();

// Register
router.post('/register', authLimiter, async (req, res) => {
  try {
    const { email, password, firstName, lastName } = req.body;
    
    // Validate inputs
    if (!email || !password || !firstName || !lastName) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields'
      });
    }
    
    // Check if user exists
    const existingUser = await knex('users').where({ email }).first();
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'User already exists'
      });
    }
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, authConfig.password.saltRounds);
    
    // Create user
    const userId = uuidv4();
    await knex('users').insert({
      id: userId,
      email,
      password_hash: hashedPassword,
      first_name: firstName,
      last_name: lastName,
      role: 'patient',
      created_at: knex.fn.now(),
      updated_at: knex.fn.now()
    });
    
    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: { id: userId }
    });
  } catch (error) {
    console.error('Error registering user:', error);
    res.status(500).json({
      success: false,
      message: 'Error registering user'
    });
  }
});

// Login
router.post('/login', authLimiter, async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Validate inputs
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }
    
    // Get user
    const user = await knex('users').where({ email }).first();
    
    // Check if user exists
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }
    
    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }
    
    // Generate tokens
    const accessToken = jwt.generateAccessToken(user);
    const refreshToken = await jwt.generateRefreshToken(user);
    
    // Update last login
    await knex('users')
      .where({ id: user.id })
      .update({ last_login: knex.fn.now() });
    
    res.status(200).json({
      success: true,
      data: {
        accessToken,
        refreshToken: refreshToken.token,
        expiresAt: refreshToken.expiresAt,
        user: {
          id: user.id,
          email: user.email,
          firstName: user.first_name,
          lastName: user.last_name,
          role: user.role
        }
      }
    });
  } catch (error) {
    console.error('Error logging in:', error);
    res.status(500).json({
      success: false,
      message: 'Error logging in'
    });
  }
});

// Refresh token
router.post('/refresh-token', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    
    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        message: 'Refresh token is required'
      });
    }
    
    const decoded = await jwt.validateRefreshToken(refreshToken);
    const user = await knex('users').where({ id: decoded.sub }).first();
    
    const accessToken = jwt.generateAccessToken(user);
    const newRefreshToken = await jwt.generateRefreshToken(user);
    
    // Revoke old refresh token
    await jwt.revokeRefreshToken(refreshToken);
    
    res.status(200).json({
      success: true,
      data: {
        accessToken,
        refreshToken: newRefreshToken.token,
        expiresAt: newRefreshToken.expiresAt
      }
    });
  } catch (error) {
    console.error('Error refreshing token:', error);
    res.status(401).json({
      success: false,
      message: 'Invalid refresh token'
    });
  }
});

// Logout
router.post('/logout', authenticate, async (req, res) => {
  try {
    const { refreshToken } = req.body;
    
    if (refreshToken) {
      await jwt.revokeRefreshToken(refreshToken);
    }
    
    res.status(200).json({
      success: true,
      message: 'Logout successful'
    });
  } catch (error) {
    console.error('Error logging out:', error);
    res.status(500).json({
      success: false,
      message: 'Error logging out'
    });
  }
});

module.exports = router;
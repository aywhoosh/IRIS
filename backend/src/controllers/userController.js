const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcrypt');
const knex = require('../utils/db');
const authConfig = require('../config/auth');

const getProfile = async (req, res) => {
  try {
    const user = await knex('users')
      .where({ id: req.user.id })
      .select('id', 'email', 'first_name', 'last_name', 'role', 'created_at')
      .first();
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    res.status(200).json({
      success: true,
      data: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        role: user.role,
        createdAt: user.created_at
      }
    });
  } catch (error) {
    console.error('Error getting user profile:', error);
    res.status(500).json({
      success: false,
      message: 'Error retrieving profile'
    });
  }
};

const updateProfile = async (req, res) => {
  try {
    const { firstName, lastName } = req.body;
    
    // Validate inputs
    if (!firstName && !lastName) {
      return res.status(400).json({
        success: false,
        message: 'No fields to update'
      });
    }
    
    const updateData = {};
    if (firstName) updateData.first_name = firstName;
    if (lastName) updateData.last_name = lastName;
    updateData.updated_at = knex.fn.now();
    
    await knex('users')
      .where({ id: req.user.id })
      .update(updateData);
    
    res.status(200).json({
      success: true,
      message: 'Profile updated successfully'
    });
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating profile'
    });
  }
};

const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    
    // Validate inputs
    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Current and new password are required'
      });
    }
    
    // Validate password complexity
    if (newPassword.length < authConfig.password.minLength) {
      return res.status(400).json({
        success: false,
        message: `Password must be at least ${authConfig.password.minLength} characters long`
      });
    }
    
    // Get user
    const user = await knex('users')
      .where({ id: req.user.id })
      .first('password_hash');
    
    // Verify current password
    const isPasswordValid = await bcrypt.compare(currentPassword, user.password_hash);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }
    
    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, authConfig.password.saltRounds);
    
    // Update password
    await knex('users')
      .where({ id: req.user.id })
      .update({
        password_hash: hashedPassword,
        updated_at: knex.fn.now()
      });
    
    res.status(200).json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (error) {
    console.error('Error changing password:', error);
    res.status(500).json({
      success: false,
      message: 'Error changing password'
    });
  }
};

module.exports = {
  getProfile,
  updateProfile,
  changePassword
};
const rateLimit = require('express-rate-limit');
const authConfig = require('../config/auth');

const authLimiter = rateLimit({
  windowMs: authConfig.rateLimit.windowMs,
  max: authConfig.rateLimit.max,
  message: {
    success: false,
    message: 'Too many requests, please try again later.'
  }
});

module.exports = {
  authLimiter
};
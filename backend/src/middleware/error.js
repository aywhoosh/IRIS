/**
 * Error handling middleware
 */

/**
 * Central error handler
 * @param {Error} err - Error object
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 * @param {Function} next - Express next
 */
const errorHandler = (err, req, res, next) => {
  // Log error
  console.error('[ERROR]', err);
  
  // Default error message
  let message = 'An unexpected error occurred';
  let statusCode = 500;
  
  // Handle specific error types
  if (err.name === 'ValidationError') {
    message = err.message;
    statusCode = 400;
  } else if (err.name === 'UnauthorizedError') {
    message = 'Authentication required';
    statusCode = 401;
  } else if (err.name === 'ForbiddenError') {
    message = 'You do not have permission to perform this action';
    statusCode = 403;
  } else if (err.name === 'NotFoundError') {
    message = err.message || 'Resource not found';
    statusCode = 404;
  }
  
  // Send error response
  res.status(statusCode).json({
    success: false,
    message,
    error: process.env.NODE_ENV === 'production' ? undefined : err.stack
  });
};

/**
 * 404 handler for routes that don't exist
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 */
const notFoundHandler = (req, res) => {
  res.status(404).json({
    success: false,
    message: `Endpoint not found: ${req.method} ${req.originalUrl}`
  });
};

// Export error handlers
module.exports = {
  errorHandler,
  notFoundHandler
};

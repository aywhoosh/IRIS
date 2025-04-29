/**
 * Processing routes for the IRIS backend
 */
const express = require('express');
const router = express.Router();
const processingController = require('../controllers/processing');
const authMiddleware = require('../middleware/auth');

// Protected routes
router.post('/', authMiddleware.authenticate, processingController.createProcessingJob);
router.get('/:jobId', authMiddleware.authenticate, processingController.getProcessingJobStatus);
router.delete('/:jobId', authMiddleware.authenticate, processingController.cancelProcessingJob);
router.get('/user/:userId', authMiddleware.authenticate, processingController.getUserProcessingJobs);

module.exports = router;

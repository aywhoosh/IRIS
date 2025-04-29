/**
 * Results routes for the IRIS backend
 */
const express = require('express');
const router = express.Router();
const resultsController = require('../controllers/results');
const authMiddleware = require('../middleware/auth');

// Protected routes
router.get('/scan/:scanId', authMiddleware.authenticate, resultsController.getDiagnosticResult);
router.get('/user/:userId', authMiddleware.authenticate, resultsController.getUserDiagnosticResults);
router.post('/:resultId/verify', authMiddleware.authenticate, authMiddleware.requireRole('doctor'), resultsController.verifyDiagnosticResult);
router.post('/:resultId/share', authMiddleware.authenticate, resultsController.generateShareableReport);
router.get('/report/:token', resultsController.getShareableReport);

module.exports = router;

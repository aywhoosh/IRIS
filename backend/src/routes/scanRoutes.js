const express = require('express');
const multer = require('multer');
const { authenticate } = require('../middleware/auth');
const scanController = require('../controllers/scanController');

const router = express.Router();

// Configure multer for memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB
  }
});

router.post('/', authenticate, upload.single('image'), scanController.uploadScan);
router.get('/', authenticate, scanController.getScans);
router.get('/:id', authenticate, scanController.getScanDetails);
router.delete('/:id', authenticate, scanController.deleteScan);

module.exports = router;
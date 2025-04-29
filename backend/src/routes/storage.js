/**
 * Storage routes for the IRIS backend
 */
const express = require('express');
const router = express.Router();
const storageController = require('../controllers/storage');
const authMiddleware = require('../middleware/auth');
const multer = require('multer');
const path = require('path');
const storageConfig = require('../config/storage');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, storageConfig.storage.tempPath);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'temp-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const fileFilter = (req, file, cb) => {
  if (storageConfig.storage.allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type. Only JPEG, PNG, and TIFF images are allowed.'), false);
  }
};

const upload = multer({
  storage: storage,
  limits: {
    fileSize: storageConfig.storage.maxFileSize
  },
  fileFilter: fileFilter
});

// Protected routes
router.post('/upload', authMiddleware.authenticate, upload.single('image'), storageController.uploadEyeScan);
router.get('/:scanId', authMiddleware.authenticate, storageController.getScanMetadata);
router.get('/:scanId/image', authMiddleware.authenticate, storageController.getScanImage);
router.delete('/:scanId', authMiddleware.authenticate, storageController.deleteScan);
router.get('/user/:userId', authMiddleware.authenticate, storageController.getUserScans);

module.exports = router;

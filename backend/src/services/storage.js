/**
 * Storage service for the IRIS backend
 * Handles image storage, retrieval, and encryption
 */
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const sharp = require('sharp');
const storageConfig = require('../config/storage');
const encryptionUtils = require('../utils/encryption');

/**
 * Store an eye scan image
 * @param {Object} fileData - File data object
 * @param {string} fileData.path - Path to temporary file
 * @param {string} fileData.originalname - Original file name
 * @param {string} fileData.mimetype - File MIME type
 * @param {Object} metadata - Image metadata
 * @param {string} metadata.patientId - Patient ID
 * @param {string} metadata.eyeSide - Eye side (left or right)
 * @param {Object} metadata.deviceInfo - Device information
 * @returns {Promise<Object>} - Stored image information
 */
const storeEyeScanImage = async (fileData, metadata) => {
  try {
    // Generate unique ID for the scan
    const scanId = uuidv4();
    
    // Create directory for this scan if it doesn't exist
    const scanDir = path.join(storageConfig.storage.basePath, scanId);
    if (!fs.existsSync(scanDir)) {
      fs.mkdirSync(scanDir, { recursive: true });
    }
    
    // Process original image
    const originalImagePath = path.join(scanDir, 'original.jpg');
    
    // Use sharp to process and optimize the image
    await sharp(fileData.path)
      .rotate() // Auto-rotate based on EXIF data
      .withMetadata({
        exif: {
          IFD0: {
            ImageDescription: 'IRIS Eye Scan',
            Copyright: 'IRIS App'
          }
        }
      })
      .jpeg({ quality: storageConfig.processing.imageQuality })
      .toFile(originalImagePath);
    
    // Generate thumbnails
    const thumbnails = {};
    for (const [size, dimensions] of Object.entries(storageConfig.processing.thumbnailSizes)) {
      const thumbnailPath = path.join(scanDir, `thumbnail_${size}.jpg`);
      
      await sharp(originalImagePath)
        .resize(dimensions.width, dimensions.height, {
          fit: 'inside',
          withoutEnlargement: true
        })
        .jpeg({ quality: 80 })
        .toFile(thumbnailPath);
      
      thumbnails[size] = thumbnailPath;
    }
    
    // Encrypt the original image if encryption is enabled
    let encryptionMetadata = null;
    if (storageConfig.encryption.enabled) {
      const encryptedImagePath = path.join(scanDir, 'encrypted.dat');
      const masterKey = process.env.ENCRYPTION_MASTER_KEY || 'default-dev-key-change-in-production';
      
      encryptionMetadata = await encryptionUtils.encryptFile(originalImagePath, encryptedImagePath, masterKey);
      
      // Delete original file if not preserving
      if (!storageConfig.processing.preserveOriginal) {
        fs.unlinkSync(originalImagePath);
      }
    }
    
    // Delete temporary upload file
    fs.unlinkSync(fileData.path);
    
    // Return scan information
    return {
      id: scanId,
      originalName: fileData.originalname,
      mimeType: fileData.mimetype,
      storagePath: scanDir,
      thumbnails,
      encrypted: storageConfig.encryption.enabled,
      encryptionMetadata,
      metadata
    };
  } catch (error) {
    // Clean up temporary file if it exists
    if (fileData.path && fs.existsSync(fileData.path)) {
      fs.unlinkSync(fileData.path);
    }
    
    throw error;
  }
};

/**
 * Retrieve an eye scan image
 * @param {string} scanId - Scan ID
 * @param {string} size - Image size (original, small, medium, large)
 * @returns {Promise<Object>} - Image data
 */
const retrieveEyeScanImage = async (scanId, size = 'original') => {
  try {
    const scanDir = path.join(storageConfig.storage.basePath, scanId);
    
    if (!fs.existsSync(scanDir)) {
      throw new Error(`Scan directory not found: ${scanId}`);
    }
    
    let imagePath;
    let contentType = 'image/jpeg';
    
    if (size === 'original') {
      if (storageConfig.encryption.enabled) {
        // Decrypt the image to a temporary file
        const encryptedImagePath = path.join(scanDir, 'encrypted.dat');
        const tempDecryptedPath = path.join(storageConfig.storage.tempPath, `decrypted_${scanId}.jpg`);
        const masterKey = process.env.ENCRYPTION_MASTER_KEY || 'default-dev-key-change-in-production';
        
        // Check if original unencrypted image exists (if preserveOriginal is true)
        const originalImagePath = path.join(scanDir, 'original.jpg');
        if (fs.existsSync(originalImagePath)) {
          imagePath = originalImagePath;
        } else {
          // Decrypt the image
          await encryptionUtils.decryptFile(encryptedImagePath, tempDecryptedPath, masterKey);
          
          // Set cleanup timeout (delete decrypted file after 5 minutes)
          setTimeout(() => {
            if (fs.existsSync(tempDecryptedPath)) {
              fs.unlinkSync(tempDecryptedPath);
            }
          }, 5 * 60 * 1000);
          
          imagePath = tempDecryptedPath;
        }
      } else {
        imagePath = path.join(scanDir, 'original.jpg');
      }
    } else {
      // Get thumbnail
      imagePath = path.join(scanDir, `thumbnail_${size}.jpg`);
    }
    
    if (!fs.existsSync(imagePath)) {
      throw new Error(`Image not found: ${imagePath}`);
    }
    
    // Read image data
    const imageData = fs.readFileSync(imagePath);
    
    return {
      data: imageData,
      contentType
    };
  } catch (error) {
    throw error;
  }
};

/**
 * Delete an eye scan
 * @param {string} scanId - Scan ID
 * @returns {Promise<boolean>} - True if scan was deleted
 */
const deleteEyeScan = async (scanId) => {
  try {
    const scanDir = path.join(storageConfig.storage.basePath, scanId);
    
    if (!fs.existsSync(scanDir)) {
      throw new Error(`Scan directory not found: ${scanId}`);
    }
    
    // Delete all files in the directory
    const files = fs.readdirSync(scanDir);
    for (const file of files) {
      fs.unlinkSync(path.join(scanDir, file));
    }
    
    // Delete the directory
    fs.rmdirSync(scanDir);
    
    return true;
  } catch (error) {
    throw error;
  }
};

module.exports = {
  storeEyeScanImage,
  retrieveEyeScanImage,
  deleteEyeScan
};

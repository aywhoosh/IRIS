/**
 * Encryption utilities for securing sensitive data
 */
const crypto = require('crypto');
const storageConfig = require('../config/storage');

/**
 * Generate encryption key from master key
 * @param {string} salt - Salt for key derivation
 * @returns {Buffer} - Derived key
 */
const generateEncryptionKey = (salt) => {
  if (!storageConfig.encryption.masterKey) {
    throw new Error('Encryption master key not configured');
  }
  
  return crypto.pbkdf2Sync(
    storageConfig.encryption.masterKey,
    salt,
    storageConfig.encryption.pbkdf2.iterations,
    32, // 256-bit key for AES-256
    storageConfig.encryption.pbkdf2.digest
  );
};

/**
 * Encrypt data
 * @param {string|Buffer} data - Data to encrypt
 * @returns {Object} - Encrypted data with iv and salt
 */
const encrypt = (data) => {
  const salt = crypto.randomBytes(16);
  const key = generateEncryptionKey(salt);
  const iv = crypto.randomBytes(storageConfig.encryption.ivLength);
  const cipher = crypto.createCipheriv(storageConfig.encryption.algorithm, key, iv);
  
  const buffer = Buffer.isBuffer(data) ? data : Buffer.from(data);
  const encrypted = Buffer.concat([cipher.update(buffer), cipher.final()]);
  
  return {
    encrypted: encrypted.toString('base64'),
    iv: iv.toString('hex'),
    salt: salt.toString('hex'),
    algorithm: storageConfig.encryption.algorithm
  };
};

/**
 * Decrypt data
 * @param {Object} encryptedData - Object containing encrypted data and metadata
 * @returns {Buffer} - Decrypted data
 */
const decrypt = (encryptedData) => {
  const { encrypted, iv, salt, algorithm } = encryptedData;
  
  const key = generateEncryptionKey(Buffer.from(salt, 'hex'));
  const decipher = crypto.createDecipheriv(
    algorithm || storageConfig.encryption.algorithm,
    key,
    Buffer.from(iv, 'hex')
  );
  
  const encryptedBuffer = Buffer.from(encrypted, 'base64');
  return Buffer.concat([decipher.update(encryptedBuffer), decipher.final()]);
};

/**
 * Hash data for non-reversible storage (e.g. passwords)
 * @param {string} data - Data to hash
 * @returns {string} - Hashed data
 */
const hash = (data) => {
  return crypto.createHash('sha256').update(data).digest('hex');
};

module.exports = {
  encrypt,
  decrypt,
  hash
};

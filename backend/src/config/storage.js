const path = require('path');

const storageProvider = process.env.STORAGE_PROVIDER || 'local';
const localPath = process.env.STORAGE_LOCAL_PATH || './data/images';

module.exports = {
  provider: storageProvider,
  local: {
    basePath: path.resolve(process.cwd(), localPath)
  },
  allowedMimeTypes: ['image/jpeg', 'image/png'],
  maxFileSize: 10 * 1024 * 1024, // 10MB
  processing: {
    thumbnailSizes: {
      small: { width: 320, height: 240 },
      medium: { width: 640, height: 480 }
    },
    imageQuality: 80
  }
};
# IRIS Backend Porting Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Project Structure Analysis](#project-structure-analysis)
4. [Step-by-Step Porting Process](#step-by-step-porting-process)
5. [Configuration Adjustments](#configuration-adjustments)
6. [Testing the Ported Backend](#testing-the-ported-backend)
7. [Troubleshooting](#troubleshooting)

## Introduction

This guide provides detailed instructions for porting the IRIS backend system to your actual project environment. It covers the entire process from analyzing your current project structure to testing the ported backend.

## Prerequisites

Before beginning the porting process, ensure you have the following:

- Node.js 16.x or higher installed
- PostgreSQL 14.x or higher installed
- Redis 6.x or higher installed (optional, but recommended)
- Git installed
- Access to your project repository
- Basic understanding of Node.js and Express
- Administrative access to your database server

## Project Structure Analysis

Based on the provided project structure, your IRIS application follows a standard Flutter project organization with platform-specific code in separate directories and Flutter source code in the `lib` directory. The backend we've created needs to be integrated as a separate service that your Flutter app will communicate with.

### Current Project Structure

```
📦 IRIS
└── 📂 app
    ├── 📂 android                  # Android platform code
    ├── 📂 ios                      # iOS platform code
    ├── 📂 web                      # Web platform files
    ├── 📂 macos                    # macOS desktop platform
    ├── 📂 lib                      # Flutter source code
    │   ├── main.dart               # Main entry point
    │   ├── 📂 screens              # App screens
    │   ├── 📂 widgets              # Reusable UI components
    │   ├── 📂 theme                # Theming and styling
    │   ├── 📂 models               # Data models
    │   ├── 📂 services             # Business logic services
    │   └── 📂 utils                # Utility functions
    ├── 📂 assets                   # App resources
    ├── 📂 screenshots              # App screenshots for documentation
    ├── 📂 test                     # Test files
    └── pubspec.yaml                # Flutter dependencies and config
```

### Backend Structure to Port

The IRIS backend we've created has the following structure:

```
📦 iris_backend
├── 📂 src
│   ├── 📂 models                   # Database models
│   ├── 📂 controllers              # Request handlers
│   ├── 📂 routes                   # API routes
│   ├── 📂 services                 # Business logic services
│   ├── 📂 middleware               # Express middleware
│   ├── 📂 utils                    # Utility functions
│   ├── 📂 config                   # Configuration files
│   └── app.js                      # Main application file
├── 📂 docs                         # Documentation
├── 📂 scripts                      # Database scripts
├── 📂 nginx                        # Nginx configuration
├── docker-compose.yml              # Docker Compose configuration
├── Dockerfile                      # API server Dockerfile
└── Dockerfile.worker               # Worker Dockerfile
```

## Step-by-Step Porting Process

### 1. Create Backend Directory

First, create a dedicated directory for the backend in your project:

```bash
mkdir -p IRIS/backend
cd IRIS/backend
```

### 2. Initialize Node.js Project

Initialize a new Node.js project:

```bash
npm init -y
```

Edit the generated `package.json` to include the necessary dependencies:

```json
{
  "name": "iris-backend",
  "version": "1.0.0",
  "description": "Backend for IRIS retinal imaging app",
  "main": "src/app.js",
  "scripts": {
    "start": "node src/app.js",
    "dev": "nodemon src/app.js",
    "test": "jest"
  },
  "dependencies": {
    "bcrypt": "^5.1.0",
    "compression": "^1.7.4",
    "cors": "^2.8.5",
    "dotenv": "^16.0.3",
    "express": "^4.18.2",
    "express-rate-limit": "^6.7.0",
    "helmet": "^6.1.5",
    "jsonwebtoken": "^9.0.0",
    "knex": "^2.4.2",
    "morgan": "^1.10.0",
    "multer": "^1.4.5-lts.1",
    "pg": "^8.10.0",
    "redis": "^4.6.6",
    "sharp": "^0.32.1",
    "uuid": "^9.0.0",
    "ws": "^8.13.0"
  },
  "devDependencies": {
    "jest": "^29.5.0",
    "nodemon": "^2.0.22",
    "supertest": "^6.3.3"
  }
}
```

Install the dependencies:

```bash
npm install
```

### 3. Copy Backend Files

Copy the backend files from the provided implementation to your project:

```bash
# Create directory structure
mkdir -p src/{models,controllers,routes,services,middleware,utils,config}
mkdir -p docs
mkdir -p scripts
mkdir -p nginx/{conf.d,ssl,logs}

# Copy files from the provided implementation
# Replace /path/to/iris_backend with the actual path to the provided implementation
cp -r /path/to/iris_backend/src/* src/
cp -r /path/to/iris_backend/docs/* docs/
cp -r /path/to/iris_backend/scripts/* scripts/
cp -r /path/to/iris_backend/nginx/* nginx/
cp /path/to/iris_backend/docker-compose.yml .
cp /path/to/iris_backend/Dockerfile .
cp /path/to/iris_backend/Dockerfile.worker .
```

### 4. Create Environment Configuration

Create a `.env` file in the root of your backend directory:

```
# Server Configuration
NODE_ENV=development
PORT=3000

# Database Configuration
DATABASE_URL=postgres://postgres:your_password@localhost:5432/iris

# JWT Configuration
JWT_SECRET=your_jwt_secret_key
JWT_REFRESH_SECRET=your_jwt_refresh_secret_key
JWT_EXPIRATION=1h
JWT_REFRESH_EXPIRATION=7d

# Storage Configuration
STORAGE_PROVIDER=local
STORAGE_LOCAL_PATH=./data/images
# Uncomment and fill these for cloud storage
# AWS_ACCESS_KEY_ID=your_aws_access_key
# AWS_SECRET_ACCESS_KEY=your_aws_secret_key
# AWS_REGION=your_aws_region
# AWS_S3_BUCKET=your_s3_bucket
# AZURE_STORAGE_CONNECTION_STRING=your_azure_connection_string
# AZURE_STORAGE_CONTAINER=your_azure_container

# Encryption Configuration
ENCRYPTION_MASTER_KEY=your_encryption_master_key
ENCRYPTION_ALGORITHM=aes-256-gcm

# Redis Configuration (optional)
# REDIS_URL=redis://localhost:6379
# REDIS_PASSWORD=your_redis_password
```

Replace the placeholder values with your actual configuration values.

### 5. Initialize Database

Create the database and run the initialization script:

```bash
# Create database
psql -U postgres -c "CREATE DATABASE iris;"

# Run initialization script
psql -U postgres -d iris -f scripts/init-db.sql
```

If you don't have the `init-db.sql` script, create it based on the database schema in the documentation:

```sql
-- Create users table
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  date_of_birth DATE,
  phone_number VARCHAR(20),
  role VARCHAR(20) NOT NULL DEFAULT 'patient',
  profile_image_url VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  last_login TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  email_verified BOOLEAN NOT NULL DEFAULT FALSE
);

-- Create eye_scans table
CREATE TABLE eye_scans (
  id UUID PRIMARY KEY,
  patient_id UUID NOT NULL REFERENCES users(id),
  doctor_id UUID REFERENCES users(id),
  scan_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  eye_side VARCHAR(10) NOT NULL CHECK (eye_side IN ('left', 'right')),
  image_path VARCHAR(255) NOT NULL,
  thumbnail_path VARCHAR(255),
  image_quality INTEGER,
  device_info JSONB,
  location_data JSONB,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- Create processing_jobs table
CREATE TABLE processing_jobs (
  id UUID PRIMARY KEY,
  scan_id UUID NOT NULL REFERENCES eye_scans(id),
  status VARCHAR(20) NOT NULL CHECK (status IN ('queued', 'processing', 'completed', 'failed', 'cancelled')),
  progress INTEGER NOT NULL DEFAULT 0,
  error_message TEXT,
  started_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create diagnostic_results table
CREATE TABLE diagnostic_results (
  id UUID PRIMARY KEY,
  scan_id UUID NOT NULL REFERENCES eye_scans(id),
  condition VARCHAR(50) NOT NULL,
  confidence DECIMAL(5,4) NOT NULL,
  severity VARCHAR(20) NOT NULL,
  diagnosis TEXT NOT NULL,
  processing_time INTEGER,
  ai_model_version VARCHAR(20) NOT NULL,
  verified_by_doctor UUID REFERENCES users(id),
  verification_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create recommendations table
CREATE TABLE recommendations (
  id UUID PRIMARY KEY,
  result_id UUID NOT NULL REFERENCES diagnostic_results(id),
  recommendation TEXT NOT NULL,
  priority INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create audit_logs table
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  action VARCHAR(50) NOT NULL,
  resource_type VARCHAR(50) NOT NULL,
  resource_id UUID,
  details JSONB,
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_eye_scans_patient_id ON eye_scans(patient_id);
CREATE INDEX idx_processing_jobs_scan_id ON processing_jobs(scan_id);
CREATE INDEX idx_diagnostic_results_scan_id ON diagnostic_results(scan_id);
CREATE INDEX idx_recommendations_result_id ON recommendations(result_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_resource_type ON audit_logs(resource_type);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
```

### 6. Create Data Directories

Create directories for storing images and other data:

```bash
mkdir -p data/images
mkdir -p data/temp
```

### 7. Update Configuration Files

Update the database configuration file to match your environment:

```javascript
// src/config/database.js
const knex = require('knex');
require('dotenv').config();

const db = knex({
  client: 'pg',
  connection: process.env.DATABASE_URL,
  pool: {
    min: 2,
    max: 10
  },
  migrations: {
    tableName: 'knex_migrations'
  }
});

module.exports = db;
```

Update the storage configuration file:

```javascript
// src/config/storage.js
require('dotenv').config();
const path = require('path');

const storageConfig = {
  provider: process.env.STORAGE_PROVIDER || 'local',
  
  storage: {
    maxFileSize: 10 * 1024 * 1024, // 10MB
    allowedMimeTypes: [
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/tiff'
    ],
    tempPath: path.resolve(process.env.STORAGE_LOCAL_PATH || './data/temp')
  },
  
  local: {
    basePath: path.resolve(process.env.STORAGE_LOCAL_PATH || './data/images')
  },
  
  aws: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    region: process.env.AWS_REGION,
    bucket: process.env.AWS_S3_BUCKET
  },
  
  azure: {
    connectionString: process.env.AZURE_STORAGE_CONNECTION_STRING,
    container: process.env.AZURE_STORAGE_CONTAINER
  },
  
  processing: {
    thumbnailSizes: {
      small: { width: 100, height: 100 },
      medium: { width: 300, height: 300 },
      large: { width: 600, height: 600 }
    }
  }
};

module.exports = storageConfig;
```

## Configuration Adjustments

### 1. Adjust API Base URL

Update the API base URL in your Flutter app to point to your backend server:

```dart
// lib/utils/constants.dart
class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'http://your-server-address:3000/api';
  
  // Other constants...
}
```

### 2. Configure CORS

Update the CORS configuration in your backend to allow requests from your Flutter app:

```javascript
// src/app.js
// Update the CORS configuration
app.use(cors({
  origin: ['http://localhost:3000', 'your-flutter-app-domain'],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));
```

### 3. Adjust Storage Paths

If you're using local storage, ensure the paths are correctly set up:

```javascript
// src/config/storage.js
// Update the storage paths to match your project structure
const storageConfig = {
  // ...
  local: {
    basePath: path.resolve(__dirname, '../../data/images')
  },
  // ...
};
```

### 4. Update Worker Configuration

If you're using the worker process, update its configuration:

```javascript
// src/worker.js
// Update the worker configuration
const config = {
  concurrency: process.env.WORKER_CONCURRENCY || 2,
  pollInterval: process.env.WORKER_POLL_INTERVAL || 5000,
  // ...
};
```

## Testing the Ported Backend

### 1. Start the Backend Server

Start the backend server in development mode:

```bash
cd IRIS/backend
npm run dev
```

### 2. Test API Endpoints

Use a tool like Postman or curl to test the API endpoints:

```bash
# Test health endpoint
curl http://localhost:3000/health

# Test registration endpoint
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "firstName": "John",
    "lastName": "Doe"
  }'
```

### 3. Test Database Connection

Verify that the backend can connect to the database:

```bash
# Check if tables were created
psql -U postgres -d iris -c "\dt"
```

### 4. Test Image Upload

Test the image upload functionality:

```bash
# Upload a test image
curl -X POST http://localhost:3000/api/eye-scans/upload \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "image=@/path/to/test/image.jpg" \
  -F "eyeSide=left"
```

### 5. Test Processing Pipeline

Test the image processing pipeline:

```bash
# Create a processing job
curl -X POST http://localhost:3000/api/processing \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "scanId": "SCAN_ID_FROM_PREVIOUS_STEP"
  }'

# Check job status
curl http://localhost:3000/api/processing/JOB_ID \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Troubleshooting

### Database Connection Issues

If you encounter database connection issues:

1. Verify that PostgreSQL is running:
   ```bash
   sudo systemctl status postgresql
   ```

2. Check the database connection string in your `.env` file:
   ```
   DATABASE_URL=postgres://postgres:your_password@localhost:5432/iris
   ```

3. Ensure the database exists:
   ```bash
   psql -U postgres -c "\l" | grep iris
   ```

4. Check PostgreSQL logs:
   ```bash
   sudo tail -f /var/log/postgresql/postgresql-14-main.log
   ```

### Image Upload Issues

If you encounter issues with image uploads:

1. Check file permissions on the storage directory:
   ```bash
   ls -la data/images
   sudo chmod -R 755 data
   ```

2. Verify that the storage configuration is correct:
   ```javascript
   console.log(storageConfig);
   ```

3. Check for errors in the server logs.

### Processing Pipeline Issues

If the processing pipeline is not working:

1. Ensure the worker process is running:
   ```bash
   node src/worker.js
   ```

2. Check Redis connection (if using Redis for queue):
   ```bash
   redis-cli ping
   ```

3. Verify that the processing job was created in the database:
   ```bash
   psql -U postgres -d iris -c "SELECT * FROM processing_jobs ORDER BY created_at DESC LIMIT 5;"
   ```

### API Connection Issues

If your Flutter app cannot connect to the backend:

1. Check that the backend server is running:
   ```bash
   curl http://localhost:3000/health
   ```

2. Verify that CORS is properly configured:
   ```javascript
   // Check CORS configuration in src/app.js
   ```

3. Ensure the API base URL in your Flutter app is correct:
   ```dart
   // Check apiBaseUrl in lib/utils/constants.dart
   ```

4. Check for network issues:
   ```bash
   ping your-server-address
   ```

By following this guide, you should be able to successfully port the IRIS backend to your actual project. If you encounter any issues not covered in the troubleshooting section, refer to the comprehensive documentation or seek assistance from the development team.

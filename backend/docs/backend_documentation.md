# IRIS Backend System Documentation

## Table of Contents
1.  [Introduction](#introduction)
2.  [System Architecture](#system-architecture)
3.  [Database Schema](#database-schema)
4.  [Core Services](#core-services)
    *   [Authentication](#authentication-system)
    *   [User Management](#user-management)
    *   [Image Storage (`storage.js`)](#image-storage-solution)
    *   [Job Queuing (`queueService2.js`)](#job-queuing-service)
    *   [AI Processing (`aiService2.js`)](#ai-processing-service)
5.  [RESTful API Endpoints](#restful-api-endpoints)
6.  [Security Features](#security-features)
7.  [Configuration](#configuration)
8.  [Deployment](#deployment)
9.  [Development Guide](#development-guide)
10. [Troubleshooting](#troubleshooting)

## 1. Introduction

The IRIS Backend System provides the server-side logic for the IRIS retinal imaging application. It handles user authentication, secure image storage, job queuing for AI analysis, mock AI processing of retinal images, and delivers results via a RESTful API.

**Key Features:**

*   Secure user registration and JWT-based authentication.
*   Role-based access control (e.g., patient, doctor, admin).
*   Upload and storage of eye scan images (configurable providers like local, S3, Azure).
*   Asynchronous processing of scans via a job queue.
*   Simulated AI analysis pipeline for detecting eye conditions (Normal, Conjunctivitis, Glaucoma, Cataract, Diabetic Retinopathy).
*   Progress tracking and status updates for processing jobs.
*   Storage of diagnostic results and recommendations.
*   Audit logging for key actions.

## 2. System Architecture

The backend follows a service-oriented architecture, containerized using Docker.

**Core Components:**

1.  **API Server (`app.js`, Express):** Handles HTTP requests, routing, authentication, and core business logic. Interacts with other services and the database.
2.  **Database (PostgreSQL):** Stores structured data like user profiles, scan metadata, job status, diagnostic results, and audit logs.
3.  **Job Queue (`queueService2.js`):** Manages the queue of scans waiting for AI analysis. Currently uses an in-memory queue (suitable for development; requires Redis/SQS/RabbitMQ for production). Handles job prioritization, concurrency, and status updates.
4.  **AI Processing Service (`aiService2.js`):** Performs the (simulated) analysis of retinal images. Includes preprocessing (using `sharp`), mock inference, post-processing, and result formatting.
5.  **Storage Service (`storage.js`):** Manages the storage and retrieval of eye scan images. Supports different providers and includes features like thumbnail generation (config-dependent).
6.  **NGINX Proxy (Optional but Recommended):** Acts as a reverse proxy for handling SSL termination, load balancing, and serving static files in production.
7.  **Worker Service (Conceptual/Dockerfile.worker):** In a production setup with a distributed queue, this would be a separate process instance running `queueService2.js` logic to consume jobs from the queue and call `aiService2.js`. In the current setup, `queueService2.js` runs within the main API server process using `setInterval`.

**Data Flow (Scan Processing):**

1.  Flutter App uploads an image to `/api/scans/upload` (handled by `scanController.js`).
2.  `scanController.js` saves the image using `storage.js` and creates an `eye_scans` record.
3.  `scanController.js` (or potentially `storage.js` or a dedicated route) calls `queueService2.queueJob(scanId)`.
4.  `queueService2` adds the job to its queue and persists a `processing_jobs` record with status 'queued'.
5.  `queueService2`'s `processQueue` interval picks up the job based on priority and concurrency limits.
6.  `queueService2` calls its `processJob(jobId, scanId)`.
7.  `processJob` updates job status to 'processing', retrieves the image via `storage.js`, and calls `aiService2.processEyeScan(scanId)`.
8.  `aiService2.processEyeScan` performs analysis (preprocessing, mock inference, post-processing) and returns detailed results.
9.  `processJob` receives results, saves them (`diagnostic_results`, `recommendations`) via `saveResults`, updates the `eye_scans` record (e.g., image quality), and updates the job status to 'completed' or 'failed'.
10. Flutter App polls `/api/jobs/:jobId/status` (handled by `processingController.js` or similar) or uses WebSockets (if implemented) to get progress and final results.

## 3. Database Schema

The database schema is defined in `scripts/init-db.sql`. Key tables include:

*   `users`: Stores user profile information, credentials, and roles.
*   `eye_scans`: Metadata about uploaded scans, including user ID, image path, eye side, and quality.
*   `processing_jobs`: Tracks the status (queued, processing, completed, failed, cancelled) and progress of analysis jobs.
*   `diagnostic_results`: Stores the results of the AI analysis for each scan.
*   `recommendations`: Stores specific recommendations associated with a diagnostic result.
*   `audit_logs`: Records significant actions performed by users or the system.

Refer to `scripts/init-db.sql` for detailed column definitions, constraints, and indexes.

## 4. Core Services

### Authentication System

*   **Implementation:** `controllers/authController.js`, `routes/authRoutes.js`, `middleware/auth.js`, `models/user.js`, `utils/jwt.js` (if used), `config/auth.js`.
*   **Features:** Registration, Login (email/password), JWT generation (access/refresh tokens), Password hashing (bcrypt), Middleware for protecting routes (`authenticate`, `authorize`), Password reset flow (optional).

### User Management

*   **Implementation:** `controllers/userController.js`, `routes/userRoutes.js`, `models/user.js`.
*   **Features:** Get/Update user profiles, Role-based access control for viewing/modifying user data.

### Image Storage Solution (`storage.js`)

*   **Implementation:** `services/storage.js`, `controllers/storageController.js` (if exists, or integrated into `scanController.js`), `routes/storage.js` (if exists), `config/storage.js`.
*   **Features:** Handles image uploads, retrieval, and deletion. Abstracted to potentially support local filesystem, AWS S3, Azure Blob Storage based on configuration. May include thumbnail generation, metadata stripping, and secure URL generation depending on implementation details.

### Job Queuing Service (`queueService2.js`)

*   **Implementation:** `services/queueService2.js`.
*   **Features:**
    *   Manages an in-memory job queue (needs external queue like Redis for production).
    *   Initializes by loading pending jobs from the DB.
    *   Processes jobs based on priority and concurrency limits (`MAX_CONCURRENT_JOBS`).
    *   Provides functions: `queueJob`, `getJobStatus`, `cancelJob`, `updateJobProgress`.
    *   Coordinates the processing flow by calling `aiService2.js`.
    *   Updates job status and progress in the `processing_jobs` table.

### AI Processing Service (`aiService2.js`)

*   **Implementation:** `services/aiService2.js`.
*   **Features:**
    *   Simulates a realistic AI pipeline for retinal image analysis.
    *   `preprocessImage`: Uses `sharp` to resize/normalize images.
    *   `runModelInference`: Simulates model execution, generating mock probabilities for conditions.
    *   `postprocessResults`: Determines the top condition and severity.
    *   `formatResults`: Adds human-readable diagnosis and recommendations.
    *   `processEyeScan`: Orchestrates the analysis for a given `scanId`, interacting with the database and other functions within the service.

## 5. RESTful API Endpoints

(Based on typical structure and provided files like `authRoutes.js`, `scanController.js`, `userController.js`)

*   **Authentication:**
    *   `POST /api/auth/register`: Register a new user.
    *   `POST /api/auth/login`: Authenticate and receive JWT tokens.
    *   `POST /api/auth/refresh-token`: Refresh access token.
    *   `POST /api/auth/logout`: Logout (requires token blacklisting implementation).
    *   *(Optional: Password Reset, Email Verification)*
*   **Users:**
    *   `GET /api/users/me`: Get current user's profile.
    *   `PUT /api/users/me`: Update current user's profile.
    *   `PUT /api/users/me/password`: Change current user's password.
    *   *(Admin endpoints for managing other users)*
*   **Eye Scans:**
    *   `POST /api/scans/upload`: Upload a new eye scan image (requires auth, multipart/form-data). Triggers job queuing.
    *   `GET /api/scans/user/me`: Get a list of scans for the current user.
    *   `GET /api/scans/:scanId`: Get metadata for a specific scan.
    *   `GET /api/scans/:scanId/image`: Retrieve the image for a specific scan (requires auth, potentially role checks).
    *   `DELETE /api/scans/:scanId`: Delete a scan and associated data (requires auth, permissions).
*   **Processing Jobs:**
    *   `GET /api/jobs/:jobId/status`: Get the status and progress of a specific processing job.
    *   `POST /api/jobs/:jobId/cancel`: Cancel a queued or processing job.
    *   *(Maybe `POST /api/scans/:scanId/process` to manually trigger processing if not automatic)*
*   **Diagnostic Results:**
    *   `GET /api/results/scan/:scanId`: Get the diagnostic result for a completed scan.
    *   `GET /api/results/:resultId`: Get a specific diagnostic result by its ID.
    *   `GET /api/results/user/me`: Get all results for the current user.

*Note: Specific endpoints depend on the implementation in the `routes/` and `controllers/` directories.*

## 6. Security Features

*   **Authentication:** JWT tokens, password hashing (bcrypt).
*   **Authorization:** Role-based access control via middleware.
*   **Input Validation:** Implemented in controllers or using middleware (e.g., `express-validator`).
*   **Security Headers:** Using `helmet` middleware.
*   **CORS:** Configured via `cors` middleware.
*   **Rate Limiting:** Recommended for auth endpoints (e.g., using `express-rate-limit`).
*   **Data Encryption:** Sensitive configuration (secrets, keys) managed via environment variables (`.env`). Image encryption at rest/transit depends on storage provider configuration.
*   **Audit Logging:** `audit_logs` table tracks key events.

## 7. Configuration

Configuration is primarily managed through environment variables (`.env` file for development) and loaded via `dotenv`. Key configuration files:

*   `.env`: Stores sensitive data like database URLs, JWT secrets, API keys, storage credentials.
*   `src/config/knex.js` or `src/utils/db.js`: Database connection settings.
*   `src/config/storage.js`: Storage provider settings (provider type, credentials, bucket names, paths).
*   `src/config/auth.js`: JWT settings (secrets, expiration times), password complexity rules.

**Required Environment Variables (Example):**

```bash
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://user:password@host:port/database
JWT_SECRET=your_super_secret_key
JWT_REFRESH_SECRET=your_super_refresh_secret_key
JWT_ACCESS_TOKEN_EXPIRATION=1h
JWT_REFRESH_TOKEN_EXPIRATION=7d

# Storage (Example: Local)
STORAGE_PROVIDER=local
STORAGE_LOCAL_PATH=./data/images

# Storage (Example: AWS S3)
# STORAGE_PROVIDER=aws
# AWS_ACCESS_KEY_ID=...
# AWS_SECRET_ACCESS_KEY=...
# AWS_REGION=...
# AWS_S3_BUCKET=...

# Other settings
MAX_CONCURRENT_JOBS=2 # For queueService2
```

## 8. Deployment

The application is designed for containerized deployment using Docker.

*   **`Dockerfile`:** Defines the image for the main API server.
*   **`Dockerfile.worker`:** Defines the image for a potential separate worker process (useful with external queues).
*   **`docker-compose.yml`:** Orchestrates the deployment of the API server, database (PostgreSQL), cache/queue (Redis - recommended), and potentially NGINX.
*   **NGINX Configuration (`nginx/`):** Provides configuration for using Nginx as a reverse proxy.

**Production Considerations:**

*   Use a managed PostgreSQL database.
*   Use Redis or a cloud queue service (SQS, RabbitMQ) instead of the in-memory queue.
*   Configure `queueService2.js` to use the chosen distributed queue system.
*   Run `queueService2` logic in separate worker containers (`Dockerfile.worker`) scaled independently.
*   Configure NGINX for SSL termination, load balancing, caching, and security headers.
*   Manage secrets securely (e.g., AWS Secrets Manager, HashiCorp Vault).
*   Implement robust logging and monitoring.

## 9. Development Guide

**Prerequisites:**

*   Node.js (>= 16.x recommended)
*   npm or yarn
*   Docker and Docker Compose
*   PostgreSQL client (e.g., `psql`)

**Setup:**

1.  **Clone the repository.**
2.  **Navigate to the `backend` directory:** `cd backend`
3.  **Install dependencies:** `npm install`
4.  **Create `.env` file:** Copy `.env.example` (if exists) or create a new `.env` file and populate it with necessary variables (see [Configuration](#configuration)).
5.  **Start Database:** Use Docker Compose to start the database (and Redis if configured):
    ```bash
    docker-compose up -d db # Add redis if in docker-compose.yml
    ```
6.  **Initialize Database Schema:** Run the init script against your database:
    ```bash
    # Example using psql (adjust connection details)
    psql -U your_db_user -d your_db_name -h localhost -f scripts/init-db.sql
    ```
    *(Alternatively, configure and use Knex migrations)*
7.  **Start the development server:**
    ```bash
    npm run dev
    ```
    *(This typically uses `nodemon` for auto-reloading)*

**Running Tests:**

```bash
npm test
```
*(Requires setting up a test database and environment)*

## 10. Troubleshooting

*   **Database Connection Issues:** Verify `DATABASE_URL` in `.env`. Ensure the PostgreSQL server is running and accessible. Check firewall rules.
*   **Authentication Errors:** Double-check JWT secrets in `.env`. Ensure tokens are not expired. Verify password hashing logic.
*   **Image Upload Failures:** Check `STORAGE_PROVIDER` and associated credentials/paths in `.env` and `config/storage.js`. Ensure the storage destination (local directory, S3 bucket) exists and has correct permissions. Check file size limits (`config/storage.js`).
*   **Job Processing Issues:** Ensure `queueService2.js` is initialized correctly. Check logs for errors during job processing (`processJob`, `aiService2.processEyeScan`). If using an external queue, ensure workers are connected and consuming jobs. Verify `MAX_CONCURRENT_JOBS` setting.
*   **Dependency Problems:** Delete `node_modules` and `package-lock.json`, then run `npm install` again.
*   **CORS Errors:** Ensure the frontend origin is correctly configured in `cors` middleware options in `app.js`.

Refer to application logs for detailed error messages.

# IRIS App Database Schema

This document outlines the database schema for the IRIS retinal imaging application backend. The schema is designed to support user management, eye scan storage, diagnostic results, and HIPAA compliance requirements.

## Database Tables

### Users Table

Stores user authentication and profile information.

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  date_of_birth DATE,
  phone_number VARCHAR(20),
  role VARCHAR(20) NOT NULL DEFAULT 'patient', -- patient, doctor, admin
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  last_login TIMESTAMP WITH TIME ZONE,
  account_status VARCHAR(20) NOT NULL DEFAULT 'active', -- active, inactive, suspended
  email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  profile_image_url TEXT,
  reset_token VARCHAR(255),
  reset_token_expires TIMESTAMP WITH TIME ZONE
);
```

### Patients Table

Stores additional patient-specific information.

```sql
CREATE TABLE patients (
  id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  medical_record_number VARCHAR(50) UNIQUE,
  gender VARCHAR(20),
  height DECIMAL(5,2), -- in cm
  weight DECIMAL(5,2), -- in kg
  blood_type VARCHAR(10),
  allergies TEXT,
  medical_conditions TEXT,
  medications TEXT,
  emergency_contact_name VARCHAR(100),
  emergency_contact_phone VARCHAR(20),
  insurance_provider VARCHAR(100),
  insurance_policy_number VARCHAR(100),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
```

### Doctors Table

Stores additional doctor-specific information.

```sql
CREATE TABLE doctors (
  id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  license_number VARCHAR(50) UNIQUE NOT NULL,
  specialization VARCHAR(100),
  clinic_name VARCHAR(100),
  clinic_address TEXT,
  clinic_phone VARCHAR(20),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
```

### Eye Scans Table

Stores metadata about eye scan images.

```sql
CREATE TABLE eye_scans (
  id UUID PRIMARY KEY,
  patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  doctor_id UUID REFERENCES users(id) ON DELETE SET NULL,
  image_path TEXT NOT NULL, -- Path to the image in secure storage
  image_hash VARCHAR(255) NOT NULL, -- Hash of the image for integrity verification
  scan_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  eye_side VARCHAR(10) NOT NULL, -- left, right
  image_quality DECIMAL(5,2), -- Quality score from 0-100
  device_info TEXT, -- Information about the device used for scanning
  location_data TEXT, -- Optional location data (encrypted)
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete
);
```

### Diagnostic Results Table

Stores the results of AI analysis on eye scans.

```sql
CREATE TABLE diagnostic_results (
  id UUID PRIMARY KEY,
  scan_id UUID NOT NULL REFERENCES eye_scans(id) ON DELETE CASCADE,
  condition VARCHAR(100) NOT NULL, -- normal, conjunctivitis, glaucoma, cataract, diabeticRetinopathy, etc.
  confidence DECIMAL(5,4) NOT NULL, -- Confidence score from 0-1
  severity VARCHAR(20), -- none, low, moderate, high
  diagnosis TEXT, -- Detailed diagnosis text
  processing_time INTEGER, -- Processing time in milliseconds
  ai_model_version VARCHAR(50) NOT NULL, -- Version of the AI model used
  verified_by_doctor UUID REFERENCES users(id) ON DELETE SET NULL,
  verification_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
```

### Recommendations Table

Stores recommendations based on diagnostic results.

```sql
CREATE TABLE recommendations (
  id UUID PRIMARY KEY,
  result_id UUID NOT NULL REFERENCES diagnostic_results(id) ON DELETE CASCADE,
  recommendation TEXT NOT NULL,
  priority INTEGER NOT NULL, -- Order of recommendations
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
```

### Processing Jobs Table

Tracks the status of image processing jobs.

```sql
CREATE TABLE processing_jobs (
  id UUID PRIMARY KEY,
  scan_id UUID NOT NULL REFERENCES eye_scans(id) ON DELETE CASCADE,
  status VARCHAR(20) NOT NULL, -- queued, processing, completed, failed
  progress DECIMAL(5,2) DEFAULT 0, -- Progress percentage from 0-100
  error_message TEXT,
  started_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
```

### Audit Logs Table

Tracks all actions for HIPAA compliance and security.

```sql
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action VARCHAR(100) NOT NULL, -- login, logout, view, create, update, delete
  resource_type VARCHAR(50) NOT NULL, -- user, scan, result, etc.
  resource_id UUID,
  ip_address VARCHAR(45),
  user_agent TEXT,
  details JSONB,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
```

### Refresh Tokens Table

Stores refresh tokens for JWT authentication.

```sql
CREATE TABLE refresh_tokens (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR(255) NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  revoked BOOLEAN NOT NULL DEFAULT FALSE,
  revoked_at TIMESTAMP WITH TIME ZONE
);
```

### User Sessions Table

Tracks active user sessions.

```sql
CREATE TABLE user_sessions (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id VARCHAR(255),
  ip_address VARCHAR(45),
  user_agent TEXT,
  last_active TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);
```

## Indexes

To optimize query performance, the following indexes should be created:

```sql
-- Users table indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- Eye scans table indexes
CREATE INDEX idx_eye_scans_patient_id ON eye_scans(patient_id);
CREATE INDEX idx_eye_scans_scan_date ON eye_scans(scan_date);
CREATE INDEX idx_eye_scans_doctor_id ON eye_scans(doctor_id);

-- Diagnostic results table indexes
CREATE INDEX idx_diagnostic_results_scan_id ON diagnostic_results(scan_id);
CREATE INDEX idx_diagnostic_results_condition ON diagnostic_results(condition);
CREATE INDEX idx_diagnostic_results_verified_by_doctor ON diagnostic_results(verified_by_doctor);

-- Processing jobs table indexes
CREATE INDEX idx_processing_jobs_scan_id ON processing_jobs(scan_id);
CREATE INDEX idx_processing_jobs_status ON processing_jobs(status);

-- Audit logs table indexes
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_resource_type_id ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- Refresh tokens table indexes
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);
```

## Data Relationships

1. **Users to Eye Scans**: One-to-many relationship. A user can have multiple eye scans.
2. **Eye Scans to Diagnostic Results**: One-to-one relationship. Each eye scan has one diagnostic result.
3. **Diagnostic Results to Recommendations**: One-to-many relationship. Each diagnostic result can have multiple recommendations.
4. **Eye Scans to Processing Jobs**: One-to-one relationship. Each eye scan has one processing job.
5. **Users to Audit Logs**: One-to-many relationship. A user can have multiple audit log entries.

## Data Security Considerations

1. **Encryption**: Sensitive fields should be encrypted at rest.
2. **Data Anonymization**: Patient identifiable information should be separable from medical data for research purposes.
3. **Access Control**: Role-based access control should be implemented to restrict data access.
4. **Audit Trail**: All data access and modifications should be logged for compliance.
5. **Data Retention**: Policies should be implemented for data retention and deletion.

## Database Technology Recommendations

For this application, we recommend using PostgreSQL for the following reasons:

1. Strong support for JSON data types (JSONB) for flexible data storage
2. Robust transaction support for data integrity
3. Advanced indexing capabilities for performance optimization
4. Strong security features including row-level security
5. Excellent support for UUID primary keys
6. Built-in encryption functions
7. Mature ecosystem with excellent tooling

This schema design supports the IRIS app's requirements for user management, eye scan storage, diagnostic results, and HIPAA compliance while providing flexibility for future enhancements.

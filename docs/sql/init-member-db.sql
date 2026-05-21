-- ============================================================
-- Cloud Library - Member Service Database Initialization
-- Run this on your Cloud SQL PostgreSQL instance.
-- ============================================================

-- Create database (run as postgres superuser)
CREATE DATABASE cloud_library_members;

-- Connect to the database, then create user (optional)
-- CREATE USER library_user WITH PASSWORD 'your_secure_password';
-- GRANT ALL PRIVILEGES ON DATABASE cloud_library_members TO library_user;

-- The 'members' table is auto-created by Spring Data JPA (ddl-auto: update)
-- But if you want to create it manually:

-- CREATE TABLE IF NOT EXISTS members (
--     id BIGSERIAL PRIMARY KEY,
--     name VARCHAR(255) NOT NULL,
--     email VARCHAR(255) NOT NULL UNIQUE,
--     phone VARCHAR(50),
--     address VARCHAR(500),
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

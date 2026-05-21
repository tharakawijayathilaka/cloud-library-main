#!/usr/bin/env bash
# Copy to env.sh on each GCP VM and source before pm2 start.
# Replace placeholders with your VM internal IPs / secrets.

# Platform VM (or shared internal IP of config-server)
export CONFIG_SERVER_URL=http://10.0.0.10:9000
export CONFIG_SERVER_PROFILE=git

# Eureka (service-registry VM internal IP)
export EUREKA_URL=http://10.0.0.11:9001/eureka/

# Member service (Cloud SQL via proxy)
export MEMBER_DB_URL=jdbc:postgresql://127.0.0.1:5432/cloud_library_members
export MEMBER_DB_USERNAME=CHANGE_ME
export MEMBER_DB_PASSWORD=CHANGE_ME

# MongoDB (Atlas or VM)
export BOOK_MONGO_URI=mongodb://MONGO_HOST:27017/cloud_library_books
export BORROWING_MONGO_URI=mongodb://MONGO_HOST:27017/cloud_library_borrowings

# GCS (book covers)
export STORAGE_PROVIDER=gcs
export GCS_PROJECT_ID=CHANGE_ME
export GCS_BUCKET=CHANGE_ME
export GCS_CREDENTIALS_PATH=/opt/app/keys/service-account.json

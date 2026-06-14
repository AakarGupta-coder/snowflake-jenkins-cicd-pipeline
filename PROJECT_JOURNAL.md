# Snowflake Jenkins CI/CD Pipeline — Project Journal

This document tracks every step taken to build this project from scratch.

---

## Phase 1: Infrastructure Setup ✅

### 1.1 AWS EC2 — Jenkins Server
- Launched an **Ubuntu 26.04 LTS** instance on AWS EC2 (`t2.micro`, Free Tier).
- Instance Type: `t2.micro` | Region: `ap-south-1` | Storage: default (8 GB gp3).
- Security Group configured to allow:
  - SSH (Port 22) from anywhere.
  - Custom TCP (Port 8080) from anywhere — required for the Jenkins web UI.
- Key Pair: RSA `.pem` file generated during launch.

### 1.2 Jenkins Installation
- Installed **OpenJDK 21**, Git, Python3 on the EC2 instance via SSH.
- Added the official Jenkins APT repository (using the `jenkins.io-2026.key`).
- Installed **Jenkins 2.555.3** and started it as a systemd service.
- Accessed Jenkins at `http://<EC2_PUBLIC_IP>:8080`.
- Completed the Setup Wizard: installed suggested plugins and created an admin user.

### 1.3 AWS S3 Bucket
- Created bucket: `snowflake-jenkins-data-ak`.
- Region: `ap-south-1`.
- Settings: Block all public access enabled, SSE-S3 encryption, Bucket Key enabled, Versioning disabled.

### 1.4 Snowflake Configuration
- Logged into Snowflake Trial account (ACCOUNTADMIN role).
- Created:
  - Database: `DATAOPS_DB`
  - Schema: `DATAOPS_DB.STAGING`
  - Warehouse: `DATAOPS_WH` (XSMALL, auto-suspend 60s)
  - Role: `JENKINS_ROLE` (with full privileges on DB and schema)
  - User: `JENKINS_USER` (service account for Jenkins to connect)

---

## Phase 2: Codebase & Database Migrations 🔄

### 2.1 Git Repository
- Initialized a local Git repository.
- Created a `migrations/` folder to hold versioned SQL scripts.
- Connected to GitHub remote: `https://github.com/AakarGupta-coder/snowflake-jenkins-cicd-pipeline`

### 2.2 First Migration Script
- File: `migrations/V1.1.1__initial_objects.sql`
- Creates a `PATIENTS` table (HCLS domain) with realistic sample data.
- Naming convention follows `schemachange` standards: `V<version>__<description>.sql`

---

## Phase 3: CI/CD Pipeline Automation (Upcoming)
- Write a `Jenkinsfile` with stages: Checkout → Lint → Deploy to Snowflake.
- Store Snowflake and AWS credentials securely in Jenkins Credentials Manager.
- Configure a GitHub Webhook to auto-trigger the pipeline on `git push`.

## Phase 4: Advanced Features (Upcoming)
- Snowpipe integration for real-time S3 → Snowflake ingestion.
- Data quality test stage in the pipeline.
- Slack/Email notifications on build success or failure.

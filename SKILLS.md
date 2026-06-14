# SKILLS.md — Snowflake Jenkins CI/CD Pipeline: Complete Project Context

> **Purpose:** This document captures every single detail, decision, discussion, troubleshooting step, and configuration choice made during the building of this project. It is intended to be handed to any AI assistant (e.g., Codex, Copilot) so it has full, word-for-word context of everything that has been done and discussed.

> **Last Updated:** 2026-06-15T03:51:00+05:30

---

## 1. Project Overview

### 1.1 What Is This Project?
This is a professional-level **Automated DataOps CI/CD Pipeline** that uses **Jenkins** (hosted on **AWS EC2**) to automatically test and deploy version-controlled **Snowflake** database changes (tables, views, stored procedures) whenever a developer commits SQL code to a **GitHub** repository.

### 1.2 Why Was This Project Chosen?
The user was tasked with creating a professional-level project using Jenkins and Snowflake. The user stated they would do everything from scratch except the Snowflake account setup. They also mentioned having an AWS account. After discussion, the "Automated DataOps CI/CD Pipeline" was chosen because:
- In modern data teams, nobody runs `CREATE TABLE` manually in the Snowflake UI.
- Everything is version-controlled and deployed via CI/CD pipelines.
- This project demonstrates understanding of modern DataOps workflows.
- It is heavily used in the industry right now.

### 1.3 High-Level Architecture
1. **Version Control (GitHub):** All Snowflake SQL scripts (DDL/DML) are stored here.
2. **AWS EC2 (Compute):** An Ubuntu EC2 instance hosts the Jenkins server.
3. **AWS S3 (Storage):** An S3 bucket serves as an External Stage for Snowflake. Raw data (CSV/JSON) is uploaded here.
4. **Jenkins (CI/CD):** Jenkins listens for changes in the Git repository. On commit, it pulls code and runs a pipeline.
5. **Database Migration Tool (`schemachange`):** Jenkins uses a Python-based tool called `schemachange` to automatically apply SQL changes to Snowflake in a version-controlled, idempotent way.
6. **Snowflake (Data Warehouse):** The target database where tables are created and data from S3 is ingested.

### 1.4 Domain
The project uses **Healthcare & Life Sciences (HCLS)** as the data domain. The user explicitly requested realistic HCLS data instead of generic employee data.

---

## 2. User's Environment & Constraints

| Item | Detail |
|---|---|
| **Local OS** | Windows (PowerShell is the default shell) |
| **Local Machine Name** | Terminator-Mk2 |
| **Windows User** | `Aakar` |
| **Project Folder** | `c:\Users\Aakar\Downloads\new-project` |
| **Snowflake Account** | Trial account (1-month duration). Account was already set up before the project started. |
| **AWS Account** | Trial / Free Tier account. |
| **Jenkins** | Did NOT exist before this project. Installed from scratch on AWS EC2. |
| **AWS CLI** | NOT installed on the local machine. The user chose to create AWS resources manually via the AWS Console instead. |
| **GitHub Account** | Username: `AakarGupta-coder` |
| **GitHub Repository** | `https://github.com/AakarGupta-coder/snowflake-jenkins-cicd-pipeline` |
| **Existing Related Repo** | The user mentioned having an existing repo called `snowpipe-s3-realtime-ingestion`. The naming convention for this new repo was chosen to match that style. |

---

## 3. Phase 1: Infrastructure Setup (COMPLETED)

### 3.1 AWS EC2 — Jenkins Server

#### 3.1.1 Instance Configuration (User Created Manually via AWS Console)
| Setting | Value Chosen | Rationale |
|---|---|---|
| **Instance Name** | (User chose their own) | — |
| **AMI (OS)** | Ubuntu 26.04 LTS | User asked if 26.04 was fine. Confirmed it is the latest LTS and works perfectly. |
| **Instance Type** | t2.micro | Free Tier eligible. |
| **Key Pair Name** | `ak-jenkins-key` | — |
| **Key Pair Type** | RSA | User asked whether to use RSA or ED25519. ED25519 was recommended as the modern/secure option, but RSA was ultimately recommended for beginners due to universal compatibility with tutorials and tools. User went with RSA. |
| **Key Pair Format** | `.pem` | — |
| **Key File Location** | Was in `c:\Users\Aakar\Downloads\new-project\ak-jenkins-key.pem` during setup. No longer in the folder (cleaned up). |
| **Storage** | Default (8 GB, gp3) | User was told AWS Free Tier allows up to 30 GB of EBS. The 30 GB claim was questioned by the user — confirmed it is explicitly stated in the AWS Free Tier policy. User opted for the default to be safe. |
| **Region** | `ap-south-1` (Mumbai) | Inferred from the EC2 hostname `ip-172-31-3-239` and the APT mirror `ap-south-1.ec2.archive.ubuntu.com`. |

#### 3.1.2 Network / Security Group Configuration
The user initially did NOT configure port 8080 correctly. After Jenkins was installed, the user reported "Site can't be reached." Diagnosis confirmed Jenkins was listening on port 8080 (`sudo ss -tulpn | grep 8080` showed it), but the AWS Security Group was blocking external access.

**Fix:** User was guided to:
1. Go to EC2 Dashboard → Instances → Click instance → Security tab.
2. Click on the Security Group link.
3. Edit Inbound Rules → Add Rule:
   - Type: Custom TCP
   - Port Range: `8080`
   - Source: Anywhere-IPv4 (`0.0.0.0/0`)
4. Save rules.

**Final Inbound Rules:**
| Type | Port | Source |
|---|---|---|
| SSH | 22 | 0.0.0.0/0 |
| HTTP | 80 | 0.0.0.0/0 |
| Custom TCP | 8080 | 0.0.0.0/0 |

#### 3.1.3 EC2 Public IP
- **Public IPv4 Address:** `3.110.191.150`
- **Private IP:** `172.31.3.239` (from hostname)

---

### 3.2 Jenkins Installation — Full Troubleshooting Log

Jenkins installation was NOT straightforward. Multiple issues were encountered and resolved. Here is the complete, chronological troubleshooting history:

#### Attempt 1: Shell Script with Windows Line Endings (FAILED)
- Created a local file `install_jenkins.sh` on the Windows machine.
- Piped it to the EC2 instance via `Get-Content install_jenkins.sh | ssh ... "sudo bash -s"`.
- **Problem:** Windows added `\r\n` line endings. Bash on Linux choked on `\r` characters.
- **Errors:** `bash: line 2: set: -\r: invalid option`, `bash: line 6: $'\r': command not found`, `Error: Unable to locate package wget\r`.
- The Jenkins GPG key URL also had a `\r` appended, causing a 404 error.

#### Attempt 2: Direct SSH Commands (FAILED — GPG Key Issue)
- Switched to running commands directly via SSH (no local script file).
- **Problem:** The Jenkins APT repository used the key `jenkins.io-2023.key`, but the repository's `Release` file was signed with a different key (`7198F4B714ABFC68`).
- **Error:** `OpenPGP signature verification failed... NO_PUBKEY 7198F4B714ABFC68`.

#### Attempt 3: apt-key (FAILED)
- Tried `sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7198F4B714ABFC68`.
- **Problem:** Ubuntu 26.04 has removed `apt-key` entirely.
- **Error:** `sudo: 'apt-key': command not found`.

#### Attempt 4: GPG Dearmor (FAILED)
- Tried downloading the key and dearmoring it with `gpg --dearmor`.
- Still got the same `NO_PUBKEY` error because the key file itself was outdated.

#### Attempt 5: GPG Keyserver Direct (FAILED)
- Tried `sudo gpg --no-default-keyring --keyring ... --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7198F4B714ABFC68`.
- **Error:** `gpg: can't connect to the dirmngr: No such file or directory`.

#### Attempt 6: Discovered the 2026 Key (SUCCESS)
- Scraped the Jenkins download page (`curl -s https://pkg.jenkins.io/debian-stable/`) and discovered a newer key: `jenkins.io-2026.key`.
- Downloaded the 2026 key: `sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key`.
- Updated `/etc/apt/sources.list.d/jenkins.list` to reference the new key.
- `sudo apt update` succeeded. Jenkins package was found and installed.
- **Jenkins version installed:** `2.555.3`.

#### Post-Install Issue: Jenkins Failed to Start (Java Not Found)
- After installation, `sudo systemctl start jenkins` failed.
- **Error in journalctl:** `jenkins: failed to find a valid Java installation`.
- **Root Cause:** Jenkins 2.555.3 requires Java 17 or 21. Although OpenJDK 17 was installed, Jenkins on Ubuntu 26.04 preferred Java 21 and couldn't locate Java 17 properly.
- **Fix:** Installed OpenJDK 21: `sudo apt install -y openjdk-21-jdk`.
- After installing Java 21, Jenkins still failed because systemd had rate-limited the restarts (`Start request repeated too quickly`).
- **Fix:** Ran `sudo systemctl reset-failed jenkins.service` then `sudo systemctl start jenkins`. Jenkins started successfully.

#### Jenkins Setup Wizard — cloudbees-folder Plugin Error
- When the user accessed `http://3.110.191.150:8080` and entered the initial admin password, the Setup Wizard crashed.
- **Error:** `An error occurred during installation: No such plugin: cloudbees-folder`.
- This is a known bug: the `cloudbees-folder` plugin was renamed to `folder` in recent Jenkins versions.
- **First fix attempt:** Suggested clicking "Retry" and "Select plugins to install" — both failed with the same error.
- **Second fix attempt (successful):** Bypassed the Setup Wizard entirely by injecting a JVM flag:
  ```bash
  sudo mkdir -p /etc/systemd/system/jenkins.service.d/
  echo -e '[Service]\nEnvironment="JAVA_OPTS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"' | sudo tee /etc/systemd/system/jenkins.service.d/override.conf > /dev/null
  sudo systemctl daemon-reload
  sudo systemctl restart jenkins
  ```
- After this, the user refreshed the page and the Setup Wizard loaded correctly this time. Suggested plugins installed successfully.

#### Jenkins Initial Admin Password
- Retrieved via: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
- **Password:** `a9e859729f89461e843aa842bee3b49f`
- User was instructed to use this to unlock Jenkins, then create a personal admin account.

#### Jenkins Admin Account
- User asked "I don't have any jenkins acc... is that fine?" — Explained that Jenkins is self-hosted and the user is creating a LOCAL account on their private server, not signing up for an internet service.
- User created an admin account through the Setup Wizard.

#### Software Installed on EC2
| Software | Version |
|---|---|
| Ubuntu | 26.04 LTS (Resolute) |
| OpenJDK | 21.0.11 |
| OpenJDK (also installed) | 17.0.19 |
| Jenkins | 2.555.3 |
| Git | (installed via apt) |
| Python3 | (installed via apt) |
| python3-pip | (installed via apt) |
| python3-venv | (installed via apt) |
| wget | (installed via apt) |

---

### 3.3 AWS S3 Bucket

#### 3.3.1 Bucket Configuration (User Created Manually via AWS Console)
| Setting | Value |
|---|---|
| **Bucket Name** | `snowflake-jenkins-data-ak` |
| **Region** | `ap-south-1` (same as EC2) |
| **Object Ownership** | ACLs disabled (recommended) |
| **Block Public Access** | ALL public access BLOCKED (checked) |
| **Bucket Versioning** | Disabled |
| **Encryption** | Server-side encryption with Amazon S3 managed keys (SSE-S3) — the default, free option. User was warned NOT to select AWS KMS as it can incur charges. |
| **Bucket Key** | Enabled (AWS optimization feature, reduces costs) |

#### 3.3.2 User Questions During S3 Setup
- **"Configure storage?"** — Answered: leave defaults for S3 bucket creation (this question was about EC2 storage, not S3).
- **"How are you sure it's free that much?"** — Explained the AWS Free Tier policy: 30 GB of EBS, 750 hours of EC2 per month for 12 months.
- **"Default encryption?"** — Answered: yes, leave the default SSE-S3. It's free and secure. Do NOT select KMS.
- **"Bucket key?"** — Answered: leave it Enabled. It's an optimization feature.

---

### 3.4 Snowflake Configuration

#### 3.4.1 SQL Script Executed by User
The user ran the following SQL in a Snowflake Worksheet (using ACCOUNTADMIN role):

```sql
USE ROLE ACCOUNTADMIN;

CREATE DATABASE IF NOT EXISTS DATAOPS_DB;
CREATE SCHEMA IF NOT EXISTS DATAOPS_DB.STAGING;

CREATE WAREHOUSE IF NOT EXISTS DATAOPS_WH 
  WITH WAREHOUSE_SIZE = 'XSMALL' 
  AUTO_SUSPEND = 60 
  AUTO_RESUME = TRUE;

CREATE ROLE IF NOT EXISTS JENKINS_ROLE;

GRANT USAGE ON WAREHOUSE DATAOPS_WH TO ROLE JENKINS_ROLE;
GRANT ALL PRIVILEGES ON DATABASE DATAOPS_DB TO ROLE JENKINS_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA DATAOPS_DB.STAGING TO ROLE JENKINS_ROLE;

CREATE USER IF NOT EXISTS JENKINS_USER 
  PASSWORD = '<user_chose_their_own_password>' 
  DEFAULT_ROLE = JENKINS_ROLE 
  DEFAULT_WAREHOUSE = DATAOPS_WH 
  MUST_CHANGE_PASSWORD = FALSE;

GRANT ROLE JENKINS_ROLE TO USER JENKINS_USER;
```

#### 3.4.2 Snowflake Setup Issues
- **Syntax Error:** The original script had `GRANT ROLE JENKINS_ROLE TO USER CURRENT_USER();` as the last line. Snowflake does not allow the `CURRENT_USER()` function inside a `GRANT` statement.
- **Error:** `SQL compilation error: syntax error line 24 at position 44 unexpected '('.`
- **Fix:** User was instructed to replace `CURRENT_USER()` with their actual Snowflake username in quotes, e.g., `GRANT ROLE JENKINS_ROLE TO USER "AAKAR";`. User confirmed they ran this successfully.

#### 3.4.3 Snowflake Objects Created
| Object Type | Name | Details |
|---|---|---|
| Database | `DATAOPS_DB` | Main database for the project |
| Schema | `DATAOPS_DB.STAGING` | Schema for staging data |
| Warehouse | `DATAOPS_WH` | XSMALL size, auto-suspend after 60 seconds, auto-resume enabled |
| Role | `JENKINS_ROLE` | Dedicated role with full privileges on DATAOPS_DB and STAGING schema |
| User | `JENKINS_USER` | Service account for Jenkins. Default role = JENKINS_ROLE, default warehouse = DATAOPS_WH |

#### 3.4.4 User Questions During Snowflake Setup
- **"Remove comments"** — User requested the SQL script be provided without any SQL comments. Script was cleaned up.

---

## 4. Phase 2: Codebase & Database Migrations (IN PROGRESS)

### 4.1 Git Repository Setup

#### 4.1.1 Local Git Initialization
- `git init` was run in `c:\Users\Aakar\Downloads\new-project`.
- A `migrations/` directory was created to hold versioned SQL scripts.
- **Note:** PowerShell does not support `&&` as a command separator. Must use `;` instead.

#### 4.1.2 Git Config
- `git config user.email "aakargupta.coder@github.com"`
- `git config user.name "AakarGupta-coder"`
- These were set locally (not `--global`) because the user's machine did not have Git identity configured.

#### 4.1.3 GitHub Remote
- Remote URL: `https://github.com/AakarGupta-coder/snowflake-jenkins-cicd-pipeline.git`
- The remote `origin` already existed from a previous init, so `git remote set-url origin ...` was used instead of `git remote add origin ...`.

#### 4.1.4 Repository Naming Discussion
The user wanted a single GitHub repo to document everything. Multiple names were suggested:
- `snowflake-jenkins-cicd-pipeline` ✅ (chosen)
- `snowflake-automated-deployment-pipeline`
- `snowflake-dataops-jenkins-integration`
- `snowflake-schema-migration-automation`

The user already had a repo named `snowpipe-s3-realtime-ingestion` and wanted something in that same descriptive style.

#### 4.1.5 Repository Description
The user asked for an elaborate description. The chosen description was:
> "A fully automated CI/CD pipeline for cloud data warehousing. Built with Jenkins hosted on AWS EC2, integrating with GitHub Webhooks to trigger idempotent schema migrations and deployments to Snowflake using DataOps best practices."

(User may have customized this before creating the repo.)

#### 4.1.6 Branch Strategy
- The user requested that all files be added within a **new branch** (not `main`).
- Branch created: `feature/jenkins-pipeline`
- Initial commit: `feat: add initial migration script and project journal`
- Pushed to GitHub successfully.

### 4.2 Files in the Repository

#### 4.2.1 Current File Structure (on branch `feature/jenkins-pipeline`)
```
snowflake-jenkins-cicd-pipeline/
├── .gitignore
├── PROJECT_JOURNAL.md
├── SKILLS.md                          ← This file
└── migrations/
    └── V1.1.1__initial_objects.sql
```

#### 4.2.2 `.gitignore`
Prevents sensitive files from being committed:
```
*.pem
*.key
.DS_Store
Thumbs.db
.vscode/
.idea/
venv/
__pycache__/
```

#### 4.2.3 `PROJECT_JOURNAL.md`
A concise project journal tracking each phase. Less detailed than this SKILLS.md file.

#### 4.2.4 `migrations/V1.1.1__initial_objects.sql`
The first database migration script. Originally created an `EMPLOYEES` table with generic data. The user requested:
1. More data.
2. More realistic data.
3. Data related to **HCLS (Healthcare & Life Sciences)**.

The script was rewritten to create a `PATIENTS` table:

```sql
USE SCHEMA DATAOPS_DB.STAGING;

CREATE TABLE IF NOT EXISTS PATIENTS (
    PATIENT_ID INT AUTOINCREMENT START 1000 INCREMENT 1,
    FIRST_NAME VARCHAR(50),
    LAST_NAME VARCHAR(50),
    DATE_OF_BIRTH DATE,
    GENDER VARCHAR(10),
    BLOOD_TYPE VARCHAR(5),
    PRIMARY_DIAGNOSIS VARCHAR(100),
    ADMISSION_DATE DATE DEFAULT CURRENT_DATE(),
    PRIMARY KEY (PATIENT_ID)
);

INSERT INTO PATIENTS (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, BLOOD_TYPE, PRIMARY_DIAGNOSIS)
VALUES 
    ('Eleanor', 'Rigby', '1955-04-12', 'Female', 'O+', 'Type 2 Diabetes Mellitus'),
    ('Marcus', 'Aurelius', '1962-11-23', 'Male', 'A-', 'Hypertension'),
    ('Clara', 'Barton', '1988-07-09', 'Female', 'AB+', 'Asthma, Unspecified'),
    ('Alexander', 'Fleming', '1945-02-18', 'Male', 'B+', 'Coronary Artery Disease'),
    ('Florence', 'Nightingale', '1971-09-30', 'Female', 'O-', 'Rheumatoid Arthritis');
```

**Naming Convention:** Files follow the `schemachange` naming standard: `V<version>__<description>.sql`. The double underscore `__` is mandatory.

---

## 5. Phase 3: CI/CD Pipeline Automation (NOT YET STARTED)

### 5.1 Planned Work
- **Jenkinsfile:** Write a declarative `Jenkinsfile` defining pipeline stages:
  - **Stage 1: Checkout** — Pull code from GitHub.
  - **Stage 2: Lint** — Validate SQL syntax.
  - **Stage 3: Deploy to Snowflake** — Run `schemachange` to apply migrations.
- **Credentials Management:** Store Snowflake username, password, account URL, and AWS keys in Jenkins Credentials Manager (never in code).
- **GitHub Webhooks:** Configure a webhook in the GitHub repo settings to trigger the Jenkins pipeline automatically on every `git push`.

### 5.2 Tools to Be Used
- **schemachange:** A Python-based database migration tool specifically designed for Snowflake. It reads versioned SQL files from a `migrations/` folder and applies them idempotently (i.e., it tracks which scripts have already been run and only applies new ones).

---

## 6. Phase 4: Advanced Features (NOT YET STARTED)

### 6.1 Planned Work
- **Snowpipe:** Automate data ingestion from the S3 bucket (`snowflake-jenkins-data-ak`) to Snowflake.
- **Data Quality Testing:** Add a Jenkins pipeline stage to run checks after deployment (e.g., check for NULLs, duplicates, row counts).
- **Notifications:** Integrate Jenkins with Slack or Email for build success/failure alerts.

---

## 7. Key Decisions & Rationale Log

| Decision | Options Discussed | Chosen | Why |
|---|---|---|---|
| EC2 setup method | AWS CLI scripting vs. Manual AWS Console | Manual Console | User is a beginner; AWS CLI was not installed locally. |
| Ubuntu version | 24.04 LTS vs. 26.04 LTS | 26.04 LTS | Latest LTS, all tooling works identically. |
| SSH Key type | RSA vs. ED25519 | RSA | Recommended for beginners due to universal compatibility. ED25519 is more modern/secure but either works. |
| EC2 storage | 8 GB vs. 20-30 GB | Default (8 GB) | User preferred to stay safe with billing. Free Tier allows up to 30 GB but user wanted to be cautious. |
| S3 encryption | SSE-S3 (default) vs. KMS | SSE-S3 | Free. KMS can incur charges. |
| Data domain | Generic (Employees) vs. HCLS | HCLS (Patients) | User explicitly requested Healthcare & Life Sciences data. |
| Repo naming | Multiple options | `snowflake-jenkins-cicd-pipeline` | Matches user's existing naming style (`snowpipe-s3-realtime-ingestion`). |
| Branch strategy | Commit to main vs. feature branch | Feature branch (`feature/jenkins-pipeline`) | User requested all work go into a new branch, not main. |
| Jenkins Setup Wizard bypass | Retry/Select plugins vs. Skip wizard | Skip wizard via JVM flag | The `cloudbees-folder` plugin error persisted on retry. Bypassing the wizard and restarting Jenkins resolved it. |

---

## 8. Connection Details & Credentials Reference

> ⚠️ **SECURITY NOTE:** These credentials were used during initial setup. In production, all credentials should be rotated and stored securely in Jenkins Credentials Manager.

| Item | Value |
|---|---|
| EC2 Public IP | `3.110.191.150` |
| EC2 SSH Command | `ssh -i ak-jenkins-key.pem ubuntu@3.110.191.150` |
| Jenkins URL | `http://3.110.191.150:8080` |
| Jenkins Initial Admin Password | `a9e859729f89461e843aa842bee3b49f` |
| Jenkins Admin Account | Created by user during Setup Wizard (username/password chosen by user) |
| S3 Bucket Name | `snowflake-jenkins-data-ak` |
| S3 Region | `ap-south-1` |
| Snowflake Database | `DATAOPS_DB` |
| Snowflake Schema | `DATAOPS_DB.STAGING` |
| Snowflake Warehouse | `DATAOPS_WH` (XSMALL) |
| Snowflake Service User | `JENKINS_USER` |
| Snowflake Service Role | `JENKINS_ROLE` |
| GitHub Repo | `https://github.com/AakarGupta-coder/snowflake-jenkins-cicd-pipeline` |
| Git Branch | `feature/jenkins-pipeline` |

---

## 9. Commands Cheat Sheet

### SSH into Jenkins Server
```bash
ssh -i ak-jenkins-key.pem ubuntu@3.110.191.150
```

### Check Jenkins Status
```bash
sudo systemctl status jenkins
```

### Restart Jenkins
```bash
sudo systemctl restart jenkins
```

### Get Jenkins Admin Password (if needed again)
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Check Java Version
```bash
java -version
```

### Check if Jenkins is Listening
```bash
sudo ss -tulpn | grep 8080
```

### Git Push Workflow (from local Windows machine)
```powershell
git add .
git commit -m "your commit message"
git push origin feature/jenkins-pipeline
```

---

## 10. What Comes Next

The immediate next step is **Phase 3: CI/CD Pipeline Automation**:
1. Write a `Jenkinsfile` with Checkout → Lint → Deploy stages.
2. Install `schemachange` on the Jenkins server.
3. Store Snowflake credentials in Jenkins Credentials Manager.
4. Create a Jenkins Pipeline job pointing to the GitHub repo.
5. Configure a GitHub Webhook to auto-trigger the pipeline.
6. Test the full end-to-end flow: commit SQL → push to GitHub → Jenkins auto-deploys to Snowflake.

After Phase 3, Phase 4 adds advanced features: Snowpipe, data quality checks, and notifications.

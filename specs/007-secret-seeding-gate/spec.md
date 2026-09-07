# Feature Specification: Secret Payload Seeding Gate

## Feature Overview & Objectives
The goal of this feature is to establish an automated pre-boot seeding script (`scripts/seed_secrets.sh`) and pre-flight validation gate that populates GCP Secret Manager with initial secret versions (`GEMINI_API_KEY`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USER_IDS`) prior to GCE VM provisioning.

This gate prevents race conditions and container startup crashes caused by GCE instances attempting to pull non-existent secret payloads from newly declared Secret Manager containers.

---

## User Stories & Acceptance Scenarios

### User Story 1: Pre-Boot Secret Seeding Automation
* **As a** Cloud Administrator,
* **I want to** execute a pre-boot secret seeding script using `gcloud` CLI or GitHub Actions variables,
* **So that** Secret Manager containers have valid active versions before VM compute creation.

#### Scenario 1.1: Idempotent Secret Payload Seeding
* **Given** valid secret credentials (`GEMINI_API_KEY`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USER_IDS`),
* **When** `scripts/seed_secrets.sh` is executed,
* **Then** the script checks for existing secret versions in GCP Secret Manager and adds a new version only if empty or modified, without failing on existing payloads.

---

### User Story 2: Deployment Pre-Flight Gate Validation
* **As a** DevOps Engineer,
* **I want** a pre-flight verification script (`scripts/verify_secret_versions.sh`),
* **So that** CI/CD deployment pipelines fail fast with clear diagnostic errors if any required secret version is missing prior to `terraform apply` for compute resources.

#### Scenario 2.1: Pre-Flight Gate Verification
* **Given** a target GCP project ID,
* **When** `scripts/verify_secret_versions.sh` runs,
* **Then** it validates that all 3 required secrets exist and contain at least 1 enabled version, exiting with status `0` on success or status `1` with actionable remediation guidance on missing versions.

---

## Functional Requirements & Specifications

### 1. Seeding Script (`scripts/seed_secrets.sh`)
- Accepts inputs from environment variables or command-line parameters (`GEMINI_API_KEY`, `TELEGRAM_BOT_TOKEN`, `ALLOWED_USER_IDS`).
- Uses `gcloud secrets versions add` to seed payloads into `gemini-api-key`, `telegram-bot-token`, and `telegram-allowed-user-ids`.

### 2. Validation Gate (`scripts/verify_secret_versions.sh`)
- Queries `gcloud secrets versions list` for each secret ID.
- Asserts state `ENABLED` for latest version.

---

## Edge Cases & Failure Modes
- **Missing Secret Payload**: VM startup script crashes if container launches before secrets are seeded. Pre-flight script halts pipeline execution before compute provisioning.
- **Malformed User IDs**: User ID secret must be numeric CSV format (e.g. `12345678,98765432`). Seeding script validates format prior to API submission.

---

## Success Criteria & Validation
- Executing `scripts/seed_secrets.sh` successfully populates all 3 secret versions in GCP Secret Manager.
- Executing `scripts/verify_secret_versions.sh` outputs verification pass status (`[PASS] All secret payloads present`).

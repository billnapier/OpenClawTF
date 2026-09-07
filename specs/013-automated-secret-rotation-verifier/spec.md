# Feature Specification: Automated Secret Rotation & Operational Health Verification Workflow

## Feature Overview & Objectives
The goal of this feature is to automate and validate safe secret rotation procedures for OpenClaw runtime credentials (`GEMINI_API_KEY`, `TELEGRAM_BOT_TOKEN`). By developing an automated secret rotation utility and verification suite (`scripts/rotate_and_verify_secrets.sh`), administrators can update API keys or bot tokens in GCP Secret Manager, execute controlled container secret re-fetching, and automatically verify container state health and persistent disk data integrity post-rotation.

---

## User Stories & Acceptance Scenarios

### User Story 1: Safe Secret Rotation Workflow
* **As a** Cloud Administrator,
* **I want** an automated workflow script (`scripts/rotate_and_verify_secrets.sh`),
* **So that** I can rotate Gemini API keys or Telegram Bot tokens in GCP Secret Manager with automated pre-flight checks and post-rotation validation.

#### Scenario 1.1: Rotating Gemini API Key Version
* **Given** a new Gemini API Key payload,
* **When** `./scripts/rotate_and_verify_secrets.sh --secret=openclaw-gemini-api-key --value=NEW_KEY` is executed,
* **Then** the script creates a new Secret Manager version, triggers container secret reload/reset, and verifies container process health.

---

### User Story 2: Post-Rotation Data Immutability & Health Verification
* **As a** Cloud Administrator,
* **I want** post-rotation automated verification,
* **So that** I am guaranteed that SQLite memory state on `/mnt/disks/openclaw-data` remains uncorrupted after container restarts.

#### Scenario 2.1: Post-Rotation Health Assertion
* **Given** a completed secret rotation operation,
* **When** the verification suite checks process logs and persistent disk SQLite database headers,
* **Then** the test asserts database health and logs zero data loss.

---

## Success Criteria & Validation
- Executable script `scripts/rotate_and_verify_secrets.sh` created supporting secret rotation and container health validation.
- Integration tests in script verifying secret payload injection and persistent disk database read access post-restart.
- Documentation updated in `docs/Runbook.md`.

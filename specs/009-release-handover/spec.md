# Feature Specification: Release Verification & Operational Handover

## Feature Overview & Objectives
The goal of this feature is to execute end-to-end verification tests (GitOps pipeline dry-run, persistent disk state immutability verification, unauthorized Telegram user ID rejection feedback per CUJ 3) and publish operational runbooks (`docs/Runbook.md`).

This ensures full operational readiness, state safety across VM replacements, and clear secret rotation and emergency recovery procedures for cloud owners.

---

## User Stories & Acceptance Scenarios

### User Story 1: Disk Immutability & State Preservation Verification
* **As a** Cloud Administrator,
* **I want to** simulate a GCE VM replacement (`terraform apply -replace`),
* **So that** I am 100% confident SQLite database state on `/mnt/disks/openclaw-data` survives VM recreation intact.

#### Scenario 1.1: VM Replacement State Survival Test
* **Given** an active OpenClaw instance with SQLite records on the persistent disk,
* **When** VM replacement is triggered via `terraform apply -replace`,
* **Then** the new VM instance mounts `/mnt/disks/openclaw-data` without reformatting, and existing database records remain intact.

---

### User Story 2: Telegram User Rejection & ID Discovery Verification (CUJ 3)
* **As a** Product Owner,
* **I want** unauthorized Telegram users to receive their numeric Telegram User ID upon access rejection,
* **So that** non-technical users can easily copy their ID to request access from administrators.

#### Scenario 2.1: Unauthorized User Rejection Feedback
* **Given** an unauthorized Telegram User ID (not present in Secret Manager `telegram-allowed-user-ids`),
* **When** the user sends any message to the bot,
* **Then** the bot returns: `"⛔ Access Denied. Your Telegram User ID is <NUMERIC_ID>. Send this ID to your OpenClaw Administrator to request access."`

---

### User Story 3: Operational Runbook & Secret Rotation Documentation
* **As a** Cloud Administrator,
* **I want** a comprehensive runbook (`docs/Runbook.md`),
* **So that** I have step-by-step procedures for secret rotation, disk snapshot backups, emergency rollbacks, and log auditing.

#### Scenario 3.1: Operational Runbook Delivery
* **Given** the completed deployment architecture,
* **When** `docs/Runbook.md` is published,
* **Then** it details secret rotation commands, disk snapshot backup schedules, log inspection via `gcloud compute instances get-serial-port-output`, and troubleshooting guides.

---

## Success Criteria & Validation
- Integration test verification script (`scripts/verify_deployment.sh`) executes and passes all assertions.
- `docs/Runbook.md` is complete and accurately covers secret rotation, backup snapshots, and disaster recovery.

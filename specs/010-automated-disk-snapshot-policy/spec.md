# Feature Specification: Automated Disk Snapshot Policy & Recovery Workflow

## Feature Overview & Objectives
The goal of this feature is to establish automated data resilience for OpenClaw's persistent state (`/mnt/disks/openclaw-data`) on Google Cloud Platform by provisioning a Terraform `google_compute_resource_policy` daily snapshot policy with 7-day retention attached to the persistent disk, along with an automated validation script (`scripts/verify_disk_snapshots.sh`).

This ensures that all conversation history, vector indices, and SQLite state survive catastrophic host failures or accidental deletions with automated, zero-touch GCP snapshot schedules.

---

## User Stories & Acceptance Scenarios

### User Story 1: Automated GCP Snapshot Resource Policy
* **As a** Cloud Administrator,
* **I want** Terraform to provision an automated daily snapshot resource policy (`google_compute_resource_policy`),
* **So that** OpenClaw persistent disk data is automatically backed up daily with a 7-day retention policy without manual scheduling.

#### Scenario 1.1: Snapshot Policy Provisioning & Attachment
* **Given** the `terraform/modules/storage` module,
* **When** `google_compute_resource_policy` is defined for daily snapshots (e.g. 04:00 UTC) with 7-day retention and attached to `openclaw-data-disk`,
* **Then** Terraform successfully creates the policy and links it to the persistent disk resource.

---

### User Story 2: Disk Snapshot Verification & Recovery Script
* **As a** Cloud Administrator,
* **I want** an executable verification script (`scripts/verify_disk_snapshots.sh`),
* **So that** I can programmatically inspect active snapshot schedules, list recent snapshots, and verify snapshot restoration integrity.

#### Scenario 2.1: Automated Snapshot Schedule Verification
* **Given** an active GCP environment with `google_compute_resource_policy` applied,
* **When** `scripts/verify_disk_snapshots.sh` is executed,
* **Then** the script asserts that the snapshot policy exists, is attached to `openclaw-data-disk`, and outputs the latest snapshot timestamp and policy details.

---

## Success Criteria & Validation
- `terraform/modules/storage` updated with `google_compute_resource_policy` daily snapshot schedule and disk attachment (`google_compute_disk_resource_policy_attachment`).
- `scripts/verify_disk_snapshots.sh` executable created and passing assertions for snapshot policy presence and disk binding.
- All Terraform configurations pass `terraform validate` and `terraform fmt`.

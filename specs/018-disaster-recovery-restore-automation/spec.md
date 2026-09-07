# Feature Specification: Automated Disaster Recovery & Snapshot Restoration Verifier

## Feature Overview & Objectives
The goal of this feature is to establish end-to-end automated disaster recovery and state restoration verification for OpenClaw. 

Building upon the daily snapshot policy (Spec 010), this feature provides `scripts/disaster_recovery_restore.sh` to automate restoring a GCP disk snapshot into a new persistent disk, attaching it to a replacement GCE VM instance, and executing automated verification assertions against the restored SQLite database to prove state continuity post-catastrophe.

---

## User Stories & Acceptance Scenarios

### User Story 1: Automated Snapshot Restoration & VM Re-binding
* **As a** Cloud Administrator,
* **I want** an automated recovery script (`scripts/disaster_recovery_restore.sh`),
* **So that** I can recover the entire OpenClaw agent state from the latest GCP disk snapshot in under 5 minutes following a catastrophic failure.

#### Scenario 1.1: Restore Disk from GCP Snapshot
* **Given** an existing daily disk snapshot in GCP,
* **When** `scripts/disaster_recovery_restore.sh --snapshot <SNAPSHOT_NAME>` is executed,
* **Then** the script creates a new GCP persistent disk from the snapshot, provisions a replacement GCE VM instance attaching the restored disk, and mounts it to `/mnt/disks/openclaw-data`.

---

### User Story 2: Post-Restoration Database & Agent Integrity Audit
* **As a** Cloud Administrator,
* **I want** automated post-recovery integrity checks,
* **So that** I can verify zero data corruption or lost messages in SQLite databases after recovery.

#### Scenario 2.1: SQLite Integrity Assertion
* **Given** a newly restored disk mounted on a replacement instance,
* **When** the restore script runs post-recovery verification,
* **Then** it executes `sqlite3 PRAGMA quick_check;` on all database files (`memory.db`, `vector_memory.db`), verifies table record counts match pre-incident metadata, and confirms the container service is healthy.

---

## Success Criteria & Validation
- Restoration script `scripts/disaster_recovery_restore.sh` created with automated snapshot lookup, disk provisioning from snapshot, and VM mounting logic.
- Post-restoration verification suite built into script validating SQLite database integrity and container health.
- Terraform configuration support for disk snapshot restoration override variable (`var.snapshot_name`).
- Dry-run verification mode supported (`--dry-run`).
- Executable validation script `scripts/test_disaster_recovery.sh` created.

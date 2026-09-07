# Implementation Plan: Automated Disk Snapshot Policy & Recovery Workflow

## Technical Approach & Architecture

To implement automated data resilience for OpenClaw's persistent disk storage (`/mnt/disks/openclaw-data`), we will extend the `terraform/modules/storage` module to create a GCP Compute Resource Policy (`google_compute_resource_policy`) for automated daily disk snapshots with a 7-day retention window. We will attach this policy to the persistent disk using `google_compute_disk_resource_policy_attachment`.

Additionally, we will create `scripts/verify_disk_snapshots.sh`, an executable verification script that validates the snapshot policy configuration, disk attachment, and snapshot inventory.

---

## File Modifications & Artifacts

### 1. `terraform/modules/storage/main.tf`
- Define `google_compute_resource_policy.snapshot_policy`:
  - Daily schedule: `04:00` UTC
  - Retention policy: `max_retention_days = 7`, `on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"`
  - Snapshot properties: custom labels `app = "openclaw"`
- Define `google_compute_disk_resource_policy_attachment.attachment`:
  - Attach `google_compute_resource_policy.snapshot_policy.name` to `google_compute_disk.openclaw_data.name`

### 2. `terraform/modules/storage/outputs.tf`
- Export `snapshot_policy_name` and `snapshot_policy_id`.

### 3. `scripts/verify_disk_snapshots.sh`
- Shell script using `gcloud` / GCP APIs to:
  1. Check for `openclaw-data-snapshot-policy` resource policy in GCP.
  2. Verify policy parameters (daily schedule, retention period = 7 days).
  3. Verify attachment to `openclaw-data-disk`.
  4. Query and display recent snapshots for the disk.

---

## Verification Plan
1. Run `terraform fmt -check` and `terraform validate` inside `terraform/`.
2. Verify `scripts/verify_disk_snapshots.sh` syntax with `bash -n scripts/verify_disk_snapshots.sh`.

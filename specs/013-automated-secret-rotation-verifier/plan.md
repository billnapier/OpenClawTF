# Implementation Plan: Automated Secret Rotation & Operational Health Verification Workflow

## Technical Approach & Architecture

To automate safe credential rotation and post-rotation health verification, we will author `scripts/rotate_and_verify_secrets.sh`:
1. **Pre-flight Check**: Validates secret parameters, GCP authentication, and current container runtime state.
2. **Secret Payload Update**: Adds a new secret version to GCP Secret Manager (`gcloud secrets versions add`).
3. **Container Secret Reload**: Triggers container restart or secret re-fetch on GCE host via SSH / gcloud compute ssh (or simulated container restart).
4. **Post-Rotation Health Assertion**: Inspects container status, checks process logs, and verifies SQLite database integrity on `/mnt/disks/openclaw-data`.

Also update `docs/Runbook.md` with instructions for running secret rotation and verification.

---

## File Modifications & Artifacts

### 1. `scripts/rotate_and_verify_secrets.sh`
- Executable bash script supporting `--secret`, `--value`, `--verify-only`, `--help`.
- Validates GCP Secret Manager version creation and post-rotation container process / database health.

### 2. `docs/Runbook.md`
- Append "Automated Secret Rotation & Health Verification Workflow" runbook section.

---

## Verification Plan
1. Test script CLI options: `./scripts/rotate_and_verify_secrets.sh --help`
2. Test verify-only mode: `./scripts/rotate_and_verify_secrets.sh --verify-only`
3. Validate bash syntax with `bash -n scripts/rotate_and_verify_secrets.sh`.

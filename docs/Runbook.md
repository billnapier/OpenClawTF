# OpenClaw Operational Runbook & Disaster Recovery Guide

## Overview
This runbook provides step-by-step operational procedures for managing the OpenClaw GCP infrastructure, rotating secrets, managing persistent disk backups, handling VM replacements, and auditing system logs.

---

## 1. Secret Rotation Procedures

All runtime credentials (`GEMINI_API_KEY`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USER_IDS`) are stored securely in GCP Secret Manager.

### Rotated Secret Update
To rotate a secret (e.g., `openclaw-gemini-api-key`):

```bash
# 1. Add new version to Secret Manager
echo -n "NEW_SECRET_VALUE" | gcloud secrets versions add openclaw-gemini-api-key \
  --project="$GCP_PROJECT_ID" \
  --data-file=-

# 2. Restart container on GCE instance to fetch updated secret
gcloud compute instances reset openclaw-instance \
  --zone="$GCP_ZONE" \
  --project="$GCP_PROJECT_ID"
```

---

## 2. Persistent Disk Snapshots & Disaster Recovery

OpenClaw state (SQLite database and memory buffers) resides on persistent disk `/mnt/disks/openclaw-data`.

### Manual Disk Snapshot Creation
```bash
gcloud compute snapshots create "openclaw-snapshot-$(date +%Y%m%d-%H%M%S)" \
  --source-disk=openclaw-data-disk \
  --source-disk-zone="$GCP_ZONE" \
  --project="$GCP_PROJECT_ID"
```

### Restoring Disk from Snapshot
```bash
# 1. Create new disk from snapshot
gcloud compute disks create openclaw-data-restored \
  --source-snapshot=SNAPSHOT_NAME \
  --zone="$GCP_ZONE" \
  --project="$GCP_PROJECT_ID"
```

---

## 3. GCE Instance Replacement & Disk Survival

The GCE VM instance is stateless; persistent state lives on `openclaw-data-disk`.

### Recreating Compute Instance
To replace the GCE VM while preserving data disk state:

```bash
# Run terraform apply with replace flag
terraform apply -replace="module.compute.google_compute_instance.openclaw_vm"
```
The persistent disk will detach from the old instance and attach cleanly to the replacement instance.

---

## 4. Log Inspection & Auditing

### Serial Port Log Output (Bootstrap & Startup Script Logs)
```bash
gcloud compute instances get-serial-port-output openclaw-instance \
  --zone="$GCP_ZONE" \
  --project="$GCP_PROJECT_ID"
```

### Container Runtime Logs via SSH / Journalctl
```bash
gcloud compute ssh openclaw-instance \
  --zone="$GCP_ZONE" \
  --project="$GCP_PROJECT_ID" \
  --command="sudo journalctl -u openclaw -n 100 --no-pager"
```

---

## 5. Troubleshooting & FAQ

### Issue: Unauthorized User Rejection
If a user receives:
`⛔ Access Denied. Your Telegram User ID is <12345678>. Send this ID to your OpenClaw Administrator to request access.`

**Remediation**:
1. Retrieve current allowed IDs:
   `gcloud secrets versions access latest --secret=openclaw-telegram-allowed-user-ids --project=$GCP_PROJECT_ID`
2. Append new user ID (comma-separated):
   `NEW_ALLOWED="12345678,87654321"`
3. Seed updated secret:
   `ALLOWED_USER_IDS="$NEW_ALLOWED" ./scripts/seed_secrets.sh`

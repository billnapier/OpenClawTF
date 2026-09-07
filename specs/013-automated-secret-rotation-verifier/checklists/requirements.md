# Quality Checklist: Secret Rotation & Verification Workflow Requirements

- [ ] **Secret Rotation Utility (`scripts/rotate_and_verify_secrets.sh`)**: Executable script created with executable permissions (`chmod +x`).
- [ ] **Payload Pre-flight Validation**: Verifies new secret payloads before writing to GCP Secret Manager.
- [ ] **Container Secret Refresh**: Safely signals/resets GCE container instance to ingest latest Secret Manager payload.
- [ ] **Data Immutability Check**: Asserts SQLite database on `/mnt/disks/openclaw-data` remains valid and accessible post-rotation.
- [ ] **Runbook Integration**: `docs/Runbook.md` updated with automated rotation commands and troubleshooting steps.

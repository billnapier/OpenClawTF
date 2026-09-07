# Quality Checklist: Release Verification & Operational Handover Requirements

- [ ] **GitOps Pipeline Dry-Run**: End-to-end verification of Guardian PR plan comments and merge deployment execution.
- [ ] **Disk Immutability Test**: Verification script asserts `/mnt/disks/openclaw-data` content survives simulated VM replacement (`terraform apply -replace`).
- [ ] **CUJ 3 Rejection UX Verification**: Unauthorized Telegram request test verifies rejection response includes sender's numeric Telegram User ID.
- [ ] **Operational Runbook (`docs/Runbook.md`)**: Comprehensive documentation published covering secret rotation, persistent disk snapshots, serial port log auditing, and emergency rollback procedures.
- [ ] **Deployment Verification Script (`scripts/verify_deployment.sh`)**: Executable script performing automated end-to-end health and policy checks.

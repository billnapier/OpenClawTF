# Quality Checklist: Disaster Recovery Restoration Requirements

- [ ] **Restoration Utility Script (`scripts/disaster_recovery_restore.sh`)**: Script created supporting `--snapshot` selection, disk creation, VM binding, and disk mounting.
- [ ] **Terraform Snapshot Override Variable**: `snapshot_name` variable added to `modules/storage` enabling disk creation from existing GCP snapshots.
- [ ] **SQLite Integrity Verification**: Automated execution of `sqlite3 PRAGMA quick_check;` and schema verification on restored persistent disk databases.
- [ ] **Dry-Run Support**: `--dry-run` flag supported for non-destructive pipeline validation of restoration steps.
- [ ] **Verification Script (`scripts/test_disaster_recovery.sh`)**: Executable validation script asserting snapshot lookup, restoration workflow execution, and post-recovery database health.

# Quality Checklist: Automated Disk Snapshot Policy Requirements

- [ ] **Resource Policy Definition**: Terraform `google_compute_resource_policy` added to `modules/storage` with 24-hour snapshot interval and 7-day snapshot retention.
- [ ] **Disk Policy Attachment**: Terraform `google_compute_disk_resource_policy_attachment` binding the snapshot policy to `openclaw-data-disk`.
- [ ] **Verification Script (`scripts/verify_disk_snapshots.sh`)**: Executable script asserting snapshot policy existence, status, and attached disk binding in GCP.
- [ ] **Idempotence & Safety**: Policy attachment preserves existing disk data without forcing disk recreation or data loss.
- [ ] **Terraform Validation**: `terraform validate` and `terraform fmt` pass without warnings or syntax errors.

# Quality Checklist: GCP Cloud Monitoring & Alerting Requirements

- [ ] **Monitoring Module (`terraform/modules/monitoring`)**: Dedicated Terraform module created and wired into root `main.tf`.
- [ ] **Log-Based Metrics (`google_logging_metric`)**: Provisioned metrics for Gemini API rate limits, unauthorized access attempts, and container restarts.
- [ ] **Alert Policies (`google_monitoring_alert_policy`)**: Cloud Monitoring alert policies configured for error rate spikes and host failures.
- [ ] **Documentation**: `docs/Runbook.md` updated with monitoring inspection procedures and alert triage steps.
- [ ] **Terraform Cleanliness**: `terraform validate` and `terraform fmt` pass cleanly.

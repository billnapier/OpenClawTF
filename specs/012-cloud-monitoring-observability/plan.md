# Implementation Plan: GCP Cloud Monitoring Alert Policies & Health Metrics

## Technical Approach & Architecture

To establish operational visibility and automated alerting for OpenClaw on GCP, we will create `terraform/modules/monitoring`:
- `google_logging_metric.rate_limit_errors`: Log metric filtering for Gemini API 429 rate limit logs.
- `google_logging_metric.unauthorized_access`: Log metric filtering for unauthorized Telegram user access attempts.
- `google_logging_metric.container_restarts`: Log metric filtering for container startup/restart logs.
- `google_monitoring_alert_policy.rate_limit_alert`: Alert policy triggering when rate-limit errors exceed threshold (count > 5 over 5m).
- `google_monitoring_alert_policy.unauthorized_access_alert`: Alert policy triggering when unauthorized access attempts exceed threshold (count > 3 over 5m).

---

## File Modifications & Artifacts

### 1. `terraform/modules/monitoring/main.tf`
- Define log metrics and monitoring alert policy resources in HCL.

### 2. `terraform/modules/monitoring/variables.tf`
- Define `project_id` variable.

### 3. `terraform/modules/monitoring/outputs.tf`
- Export alert policy names and metric names.

### 4. `terraform/modules/monitoring/versions.tf`
- Declare terraform and google provider versions.

---

## Verification Plan
1. Initialize module: `cd terraform/modules/monitoring && terraform init -backend=false`
2. Run `terraform fmt -check` and `terraform validate`.

# Feature Specification: GCP Cloud Monitoring Alert Policies & Health Metrics

## Feature Overview & Objectives
The goal of this feature is to establish real-time operational visibility and automated alerting for the OpenClaw production deployment on GCP. By introducing Terraform resources for GCP Cloud Monitoring alert policies (`google_monitoring_alert_policy`), log-based metrics (`google_logging_metric`), and health verification dashboards, Cloud Administrators receive instant notifications for Gemini API rate limits (HTTP 429), unauthorized access attempts, and unexpected VM/container restarts.

---

## User Stories & Acceptance Scenarios

### User Story 1: Log-Based Metrics for System Events
* **As a** Cloud Administrator,
* **I want** GCP Cloud Logging log-based metrics to capture critical service events,
* **So that** rate limit errors, unauthorized access attempts, and container restarts are quantified and trackable over time.

#### Scenario 1.1: Log Metric Creation via Terraform
* **Given** the `terraform/modules/compute` or new `terraform/modules/monitoring` module,
* **When** `google_logging_metric` resources are defined for:
  - `openclaw_rate_limit_errors` (filter matching HTTP 429 or rate limit log lines)
  - `openclaw_unauthorized_access_attempts` (filter matching CUJ 3 rejection log lines)
  - `openclaw_container_restarts` (filter matching container launch/restart events)
* **Then** Terraform successfully provisions the metrics in GCP Cloud Logging.

---

### User Story 2: Automated Cloud Monitoring Alert Policies
* **As a** Cloud Administrator,
* **I want** GCP Cloud Monitoring alert policies (`google_monitoring_alert_policy`),
* **So that** high rate-limit thresholds or repeated unauthorized access spikes generate operational alerts.

#### Scenario 2.1: Alert Policy Definition
* **Given** the log-based metrics created in Terraform,
* **When** `google_monitoring_alert_policy` resources are defined with threshold conditions and notification channels,
* **Then** Terraform applies the policies without error.

---

## Success Criteria & Validation
- New module `terraform/modules/monitoring` created and integrated into root `terraform/main.tf`.
- Log-based metrics created for rate limits, unauthorized attempts, and restarts.
- Alert policies defined with configurable thresholds.
- `terraform validate` and `terraform fmt` execute cleanly.

output "rate_limit_metric_name" {
  description = "Name of log metric for rate limit errors."
  value       = google_logging_metric.rate_limit_errors.name
}

output "unauthorized_access_metric_name" {
  description = "Name of log metric for unauthorized access attempts."
  value       = google_logging_metric.unauthorized_access.name
}

output "rate_limit_alert_policy_name" {
  description = "Display name of rate limit alert policy."
  value       = google_monitoring_alert_policy.rate_limit_alert.display_name
}

output "unauthorized_access_alert_policy_name" {
  description = "Display name of unauthorized access alert policy."
  value       = google_monitoring_alert_policy.unauthorized_access_alert.display_name
}

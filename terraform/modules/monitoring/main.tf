resource "google_logging_metric" "rate_limit_errors" {
  project = var.project_id
  name    = "openclaw-rate-limit-errors"
  filter  = "resource.type=\"gce_instance\" AND textPayload:\"429\" OR textPayload:\"RESOURCE_EXHAUSTED\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_logging_metric" "unauthorized_access" {
  project = var.project_id
  name    = "openclaw-unauthorized-access-attempts"
  filter  = "resource.type=\"gce_instance\" AND textPayload:\"Unauthorized access attempt\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_logging_metric" "container_restarts" {
  project = var.project_id
  name    = "openclaw-container-restarts"
  filter  = "resource.type=\"gce_instance\" AND textPayload:\"Starting OpenClaw container\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_alert_policy" "rate_limit_alert" {
  project      = var.project_id
  display_name = "OpenClaw Gemini API Rate Limit Alert"
  combiner     = "OR"

  conditions {
    display_name = "Rate Limit Error Count > ${var.rate_limit_threshold}"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.rate_limit_errors.name}\" AND resource.type=\"gce_instance\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.rate_limit_threshold

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
}

resource "google_monitoring_alert_policy" "unauthorized_access_alert" {
  project      = var.project_id
  display_name = "OpenClaw Unauthorized Access Attempt Alert"
  combiner     = "OR"

  conditions {
    display_name = "Unauthorized Access Count > ${var.unauthorized_access_threshold}"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.unauthorized_access.name}\" AND resource.type=\"gce_instance\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.unauthorized_access_threshold

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
}

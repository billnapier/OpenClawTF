resource "google_compute_disk" "openclaw_data" {
  project     = var.project_id
  name        = var.disk_name
  type        = var.disk_type
  size        = var.disk_size_gb
  zone        = var.zone
  labels      = var.labels
  description = "Persistent data disk for OpenClaw SQLite databases and vector memory storage."
}

resource "google_compute_resource_policy" "snapshot_policy" {
  project = var.project_id
  name    = "${var.disk_name}-snapshot-policy"
  region  = var.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "04:00"
      }
    }
    retention_policy {
      max_retention_days    = 7
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
    snapshot_properties {
      labels = merge(var.labels, {
        snapshot_type = "automated-daily"
      })
      storage_locations = [var.region]
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "attachment" {
  project = var.project_id
  name    = google_compute_resource_policy.snapshot_policy.name
  disk    = google_compute_disk.openclaw_data.name
  zone    = var.zone
}


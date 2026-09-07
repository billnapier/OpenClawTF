resource "google_compute_disk" "openclaw_data" {
  project     = var.project_id
  name        = var.disk_name
  type        = var.disk_type
  size        = var.disk_size_gb
  zone        = var.zone
  labels      = var.labels
  description = "Persistent data disk for OpenClaw SQLite databases and vector memory storage."
}

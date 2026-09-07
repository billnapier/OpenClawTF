output "disk_id" {
  description = "The unique ID of the provisioned GCP persistent disk."
  value       = google_compute_disk.openclaw_data.id
}

output "disk_name" {
  description = "The name of the provisioned persistent disk."
  value       = google_compute_disk.openclaw_data.name
}

output "disk_self_link" {
  description = "The self-link URL of the persistent disk."
  value       = google_compute_disk.openclaw_data.self_link
}

output "disk_size_gb" {
  description = "The allocated size of the persistent disk in gigabytes."
  value       = google_compute_disk.openclaw_data.size
}

output "snapshot_policy_name" {
  description = "The name of the automated disk snapshot resource policy."
  value       = google_compute_resource_policy.snapshot_policy.name
}


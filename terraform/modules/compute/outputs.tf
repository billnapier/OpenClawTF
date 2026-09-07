output "instance_id" {
  description = "Unique ID of the created GCE instance."
  value       = google_compute_instance.openclaw_vm.instance_id
}

output "instance_name" {
  description = "Name of the created GCE instance."
  value       = google_compute_instance.openclaw_vm.name
}

output "instance_self_link" {
  description = "Self-link URL of the created GCE instance."
  value       = google_compute_instance.openclaw_vm.self_link
}

output "internal_ip" {
  description = "Primary private IPv4 address of the instance."
  value       = google_compute_instance.openclaw_vm.network_interface[0].network_ip
}

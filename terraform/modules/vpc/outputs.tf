output "network_id" {
  description = "The ID of the provisioned VPC network."
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "The name of the provisioned VPC network."
  value       = google_compute_network.vpc.name
}

output "network_self_link" {
  description = "The self-link URL of the provisioned VPC network."
  value       = google_compute_network.vpc.self_link
}

output "subnet_id" {
  description = "The ID of the private subnetwork."
  value       = google_compute_subnetwork.subnet.id
}

output "subnet_name" {
  description = "The name of the private subnetwork."
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_self_link" {
  description = "The self-link URL of the private subnetwork."
  value       = google_compute_subnetwork.subnet.self_link
}

output "vpc_network_id" {
  description = "The ID of the VPC network."
  value       = module.vpc.network_id
}

output "vpc_subnet_id" {
  description = "The ID of the VPC subnetwork."
  value       = module.vpc.subnet_id
}

output "artifact_repository_url" {
  description = "The Artifact Registry repository URL."
  value       = module.artifact_registry.repository_url
}

output "secret_ids" {
  description = "Map of secret resource IDs."
  value       = module.secrets.secret_ids
}

output "disk_id" {
  description = "The ID of the persistent storage disk."
  value       = module.storage.disk_id
}

output "instance_id" {
  description = "The ID of the compute instance."
  value       = module.compute.instance_id
}

output "instance_internal_ip" {
  description = "Internal IP address of compute instance."
  value       = module.compute.internal_ip
}

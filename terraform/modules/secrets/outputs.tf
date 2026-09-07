output "secret_ids" {
  description = "Map of secret key names to their GCP Secret Manager resource IDs."
  value       = { for k, v in google_secret_manager_secret.secrets : k => v.secret_id }
}

output "secret_names" {
  description = "Map of secret key names to their fully qualified secret names."
  value       = { for k, v in google_secret_manager_secret.secrets : k => v.name }
}

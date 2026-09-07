output "repository_id" {
  description = "The ID of the created Artifact Registry repository"
  value       = google_artifact_registry_repository.openclaw_repo.repository_id
}

output "repository_name" {
  description = "The fully qualified resource name of the repository"
  value       = google_artifact_registry_repository.openclaw_repo.name
}

output "repository_url" {
  description = "The URL of the Docker repository for image tagging and pushing"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.openclaw_repo.repository_id}"
}

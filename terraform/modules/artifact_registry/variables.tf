variable "project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for the Artifact Registry repository"
  type        = string
  default     = "us-central1"
}

variable "repository_id" {
  description = "The ID of the Artifact Registry repository"
  type        = string
  default     = "openclaw"
}

variable "description" {
  description = "Description of the Artifact Registry repository"
  type        = string
  default     = "OpenClaw container image repository"
}

variable "labels" {
  description = "Labels to apply to the repository"
  type        = map(string)
  default = {
    environment = "production"
    app         = "openclaw"
  }
}

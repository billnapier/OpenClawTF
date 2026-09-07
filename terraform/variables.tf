variable "project_id" {
  type        = string
  description = "The GCP Project ID."
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "GCP Region."
}

variable "zone" {
  type        = string
  default     = "us-central1-a"
  description = "GCP Zone."
}

variable "service_account_email" {
  type        = string
  description = "Service Account email for runtime execution and secret access."
  default     = ""
}

variable "container_image" {
  type        = string
  description = "Container image URI for GCE compute instance."
  default     = ""
}

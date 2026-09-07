variable "project_id" {
  description = "The GCP Project ID."
  type        = string
}

variable "service_account_email" {
  description = "GCE runtime Service Account email to receive Secret Accessor IAM bindings."
  type        = string
}

variable "secret_prefix" {
  description = "Optional prefix for secret IDs."
  type        = string
  default     = ""
}

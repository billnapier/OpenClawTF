variable "project_id" {
  description = "The GCP Project ID."
  type        = string
}

variable "zone" {
  description = "GCP Zone for the GCE instance."
  type        = string
  default     = "us-central1-a"
}

variable "instance_name" {
  description = "Name of the GCE VM instance."
  type        = string
  default     = "openclaw-vm"
}

variable "machine_type" {
  description = "GCE machine type."
  type        = string
  default     = "e2-standard-2"
}

variable "subnetwork_id" {
  description = "Self-link or ID of the private subnetwork from modules/vpc."
  type        = string
}

variable "persistent_disk_name" {
  description = "Disk name from modules/storage for attached_disk."
  type        = string
}

variable "service_account_email" {
  description = "Service account email with Secret Accessor role."
  type        = string
}

variable "container_image" {
  description = "Container image URI (e.g. Artifact Registry URI)."
  type        = string
}

variable "labels" {
  description = "Labels to apply to the compute instance."
  type        = map(string)
  default = {
    environment = "production"
    app         = "openclaw"
  }
}

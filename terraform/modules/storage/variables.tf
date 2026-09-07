variable "project_id" {
  description = "The GCP Project ID."
  type        = string
}

variable "zone" {
  description = "GCP Zone where the persistent disk is provisioned."
  type        = string
  default     = "us-central1-a"
}

variable "disk_name" {
  description = "Name of the GCP Persistent Disk."
  type        = string
  default     = "openclaw-data"
}

variable "disk_type" {
  description = "Disk type (pd-ssd, pd-balanced, pd-standard)."
  type        = string
  default     = "pd-ssd"
}

variable "disk_size_gb" {
  description = "Size of the persistent disk in gigabytes."
  type        = number
  default     = 20
}

variable "labels" {
  description = "Key-value labels applied to the disk."
  type        = map(string)
  default = {
    environment = "production"
    app         = "openclaw"
  }
}

variable "region" {
  description = "GCP Region where the snapshot resource policy is provisioned."
  type        = string
  default     = "us-central1"
}


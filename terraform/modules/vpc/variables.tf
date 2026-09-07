variable "project_id" {
  type        = string
  description = "The GCP Project ID where network resources are provisioned."
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "GCP region for subnetwork and NAT router."
}

variable "network_name" {
  type        = string
  default     = "openclaw-vpc"
  description = "Name of the custom VPC network."
}

variable "subnet_name" {
  type        = string
  default     = "openclaw-subnet"
  description = "Name of the private subnetwork."
}

variable "subnet_cidr" {
  type        = string
  default     = "10.0.1.0/24"
  description = "Primary IPv4 CIDR range for the private subnetwork."

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "Must be a valid IPv4 CIDR range (e.g. 10.0.1.0/24)."
  }
}

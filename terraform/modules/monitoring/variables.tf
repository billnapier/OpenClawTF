variable "project_id" {
  description = "The GCP Project ID."
  type        = string
}

variable "rate_limit_threshold" {
  description = "Threshold for rate limit errors over 5 minutes to trigger alert."
  type        = number
  default     = 5
}

variable "unauthorized_access_threshold" {
  description = "Threshold for unauthorized access attempts over 5 minutes to trigger alert."
  type        = number
  default     = 3
}

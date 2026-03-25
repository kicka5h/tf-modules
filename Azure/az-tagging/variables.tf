variable "environment" {
  description = "Deployment environment (dev, qa, stage, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "stage", "prod"], var.environment)
    error_message = "environment must be one of: dev, qa, stage, prod"
  }
}

variable "owner" {
  description = "Team or individual responsible for this infrastructure"
  type        = string

  validation {
    condition     = length(var.owner) > 0
    error_message = "owner tag is required"
  }
}

variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string

  validation {
    condition     = length(var.cost_center) > 0
    error_message = "cost_center tag is required"
  }
}

variable "data_classification" {
  description = "Data classification level (public, internal, confidential, restricted)"
  type        = string
  default     = "internal"

  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "data_classification must be one of: public, internal, confidential, restricted"
  }
}

variable "project" {
  description = "Project or workload name"
  type        = string

  validation {
    condition     = length(var.project) > 0
    error_message = "project tag is required"
  }
}

variable "managed_by" {
  description = "Tool or process managing this infrastructure"
  type        = string
  default     = "terraform"
}

variable "additional_tags" {
  description = "Additional custom tags to merge with required tags"
  type        = map(string)
  default     = {}
}

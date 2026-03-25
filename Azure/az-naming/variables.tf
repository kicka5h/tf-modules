variable "environment" {
  description = "Deployment environment (dev, qa, stage, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, stage, prod."
  }
}

variable "region" {
  description = "Azure region (e.g., eastus, westus2, westeurope)"
  type        = string
}

variable "workload" {
  description = "Short workload/project name (e.g., 'app', 'data', 'shared')"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.workload))
    error_message = "Workload must be lowercase alphanumeric with no special characters."
  }
}

variable "separator" {
  description = "Separator character used between name components"
  type        = string
  default     = "-"
}

variable "suffix" {
  description = "Optional additional suffix appended to the name"
  type        = string
  default     = ""
}

variable "region_abbreviations" {
  description = "Map of Azure region names to short abbreviations used in resource names"
  type        = map(string)
  default = {
    "eastus"         = "eus"
    "eastus2"        = "eus2"
    "westus"         = "wus"
    "westus2"        = "wus2"
    "westus3"        = "wus3"
    "centralus"      = "cus"
    "northcentralus" = "ncus"
    "southcentralus" = "scus"
    "westeurope"     = "weu"
    "northeurope"    = "neu"
    "uksouth"        = "uks"
    "ukwest"         = "ukw"
    "canadacentral"  = "cc"
    "canadaeast"     = "ce"
    "australiaeast"  = "aue"
    "southeastasia"  = "sea"
    "japaneast"      = "jpe"
  }
}

variable "name" {
  description = "Base name used to derive the resource group and workspace names."
  type        = string
}

variable "location" {
  description = "Azure region in which to create the baseline resources."
  type        = string
}

variable "storage_account_name" {
  description = "Globally unique name of the storage account. Must be 3-24 lowercase alphanumeric characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "The storage_account_name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "log_analytics_sku" {
  description = "SKU of the Log Analytics workspace."
  type        = string
  default     = "PerGB2018"
}

variable "log_retention_in_days" {
  description = "Number of days to retain data in the Log Analytics workspace."
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_in_days >= 30 && var.log_retention_in_days <= 730
    error_message = "The log_retention_in_days must be between 30 and 730."
  }
}

variable "storage_account_tier" {
  description = "Performance tier of the storage account. One of Standard or Premium."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "The storage_account_tier must be one of Standard or Premium."
  }
}

variable "storage_account_replication_type" {
  description = "Replication type of the storage account (e.g. LRS, GRS, ZRS)."
  type        = string
  default     = "LRS"
}

variable "tags" {
  description = "Map of tags applied to all baseline resources."
  type        = map(string)
  default     = {}
}

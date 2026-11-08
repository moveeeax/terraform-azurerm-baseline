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
  description = "Replication type of the storage account. Note that the Premium tier only supports LRS and ZRS."
  type        = string
  default     = "LRS"

  validation {
    condition = contains(
      ["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"],
      var.storage_account_replication_type
    )
    error_message = "The storage_account_replication_type must be one of LRS, GRS, RAGRS, ZRS, GZRS or RAGZRS."
  }
}

variable "storage_shared_access_key_enabled" {
  description = <<-EOT
    Whether the storage account accepts shared access key (account key) authentication.
    Leave enabled if you use the account as a Terraform state backend without
    `use_azuread_auth`; set to false to require Entra ID authentication.
  EOT
  type        = bool
  default     = true
}

variable "storage_public_network_access_enabled" {
  description = "Whether the storage account is reachable from the public internet. Set to false when fronting the account with private endpoints."
  type        = bool
  default     = true
}

variable "storage_blob_retention_in_days" {
  description = "Number of days deleted blobs and containers are retained (soft delete)."
  type        = number
  default     = 7

  validation {
    condition     = var.storage_blob_retention_in_days >= 1 && var.storage_blob_retention_in_days <= 365
    error_message = "The storage_blob_retention_in_days must be between 1 and 365."
  }
}

variable "enable_activity_log_diagnostics" {
  description = "Whether to stream the subscription activity log into the Log Analytics workspace."
  type        = bool
  default     = true
}

variable "activity_log_categories" {
  description = "Activity log categories forwarded to the Log Analytics workspace."
  type        = list(string)
  default = [
    "Administrative",
    "Alert",
    "Autoscale",
    "Policy",
    "Recommendation",
    "ResourceHealth",
    "Security",
    "ServiceHealth",
  ]

  validation {
    condition     = length(var.activity_log_categories) > 0
    error_message = "At least one activity log category must be specified."
  }
}

variable "defender_plans" {
  description = <<-EOT
    Microsoft Defender for Cloud plans to set on the subscription, keyed by
    resource type (VirtualMachines, StorageAccounts, KeyVaults, Arm, ...). tier is
    Standard (paid) or Free; subplan is optional (e.g. P1/P2 for VirtualMachines).
    Plans are subscription-wide and Standard is billed per protected resource, so
    nothing is set by default.
  EOT
  type = map(object({
    tier    = optional(string, "Standard")
    subplan = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for p in values(var.defender_plans) : contains(["Free", "Standard"], p.tier)])
    error_message = "Each defender_plans tier must be Free or Standard."
  }
}

variable "security_contact" {
  description = <<-EOT
    Defender for Cloud security contact for the subscription. null (the default)
    leaves the subscription's existing contact untouched. name defaults to
    default1, the name azurerm 3.x used when it was optional.
  EOT
  type = object({
    email               = string
    phone               = optional(string)
    alert_notifications = optional(bool, true)
    alerts_to_admins    = optional(bool, true)
    name                = optional(string, "default1")
  })
  default = null

  validation {
    condition     = var.security_contact == null ? true : can(regex("^[^@\\s]+@[^@\\s]+$", var.security_contact.email))
    error_message = "security_contact.email must be an email address."
  }
}

variable "tags" {
  description = "Map of tags applied to all baseline resources."
  type        = map(string)
  default     = {}
}

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

variable "budget" {
  description = <<-EOT
    Subscription consumption budget with email alerts. null (the default) creates
    no budget. amount is in the billing currency; thresholds are percentages of
    amount (actual cost). start_date must be the first of a month in RFC 3339
    form (2026-11-01T00:00:00Z); when null, the first of the month of the first
    apply is used and later drift is ignored. name defaults to "<name>-budget".
  EOT
  type = object({
    amount         = number
    contact_emails = list(string)
    time_grain     = optional(string, "Monthly")
    thresholds     = optional(list(number), [80, 100])
    start_date     = optional(string)
    name           = optional(string)
  })
  default = null

  validation {
    condition     = var.budget == null ? true : var.budget.amount > 0
    error_message = "budget.amount must be greater than 0."
  }

  validation {
    condition     = var.budget == null ? true : length(var.budget.contact_emails) > 0 && alltrue([for e in var.budget.contact_emails : can(regex("^[^@\\s]+@[^@\\s]+$", e))])
    error_message = "budget.contact_emails must contain at least one email address, and every entry must be one."
  }

  validation {
    condition = var.budget == null ? true : contains(
      ["Monthly", "Quarterly", "Annually", "BillingMonth", "BillingQuarter", "BillingAnnual"],
      var.budget.time_grain
    )
    error_message = "budget.time_grain must be one of Monthly, Quarterly, Annually, BillingMonth, BillingQuarter or BillingAnnual."
  }

  validation {
    condition = var.budget == null ? true : (
      length(var.budget.thresholds) >= 1 &&
      length(var.budget.thresholds) <= 5 &&
      length(distinct(var.budget.thresholds)) == length(var.budget.thresholds) &&
      alltrue([for t in var.budget.thresholds : t > 0 && t <= 1000])
    )
    error_message = "budget.thresholds must hold 1 to 5 distinct percentages, each greater than 0 and at most 1000."
  }

  validation {
    condition     = var.budget == null ? true : var.budget.start_date == null ? true : can(regex("^[0-9]{4}-[0-9]{2}-01T00:00:00Z$", var.budget.start_date))
    error_message = "budget.start_date must be the first of a month, formatted like 2026-11-01T00:00:00Z."
  }
}

variable "tags" {
  description = "Map of tags applied to all baseline resources."
  type        = map(string)
  default     = {}
}

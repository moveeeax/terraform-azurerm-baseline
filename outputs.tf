output "resource_group_name" {
  description = "Name of the created resource group."
  value       = azurerm_resource_group.this.name
}

output "resource_group_id" {
  description = "ID of the created resource group."
  value       = azurerm_resource_group.this.id
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "storage_account_id" {
  description = "ID of the storage account."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the storage account."
  value       = azurerm_storage_account.this.name
}

output "activity_log_diagnostic_setting_id" {
  description = "ID of the subscription activity log diagnostic setting, or null when disabled."
  value       = one(azurerm_monitor_diagnostic_setting.activity_log[*].id)
}

output "defender_plan_ids" {
  description = "IDs of the Defender for Cloud pricing settings, keyed by resource type."
  value       = { for k, p in azurerm_security_center_subscription_pricing.this : k => p.id }
}

output "security_contact_id" {
  description = "ID of the Defender for Cloud security contact, or null when not managed."
  value       = one(azurerm_security_center_contact.this[*].id)
}

output "budget_id" {
  description = "ID of the subscription consumption budget, or null when budget is not set."
  value       = one(azurerm_consumption_budget_subscription.this[*].id)
}

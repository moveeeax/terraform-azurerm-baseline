terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.114.0, < 5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "baseline" {
  source = "../.."

  name                 = "example-platform"
  location             = "eastus"
  storage_account_name = "examplebaselinesa01"

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "resource_group_name" {
  value = module.baseline.resource_group_name
}

output "log_analytics_workspace_id" {
  value = module.baseline.log_analytics_workspace_id
}

output "activity_log_diagnostic_setting_id" {
  value = module.baseline.activity_log_diagnostic_setting_id
}

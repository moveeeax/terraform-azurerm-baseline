# Defender for Cloud plans and the security contact are subscription-wide and
# Standard plans cost money per resource, so the module must not touch either
# unless asked.
#
# Requires Terraform >= 1.7 for mock_provider. Runs offline.

mock_provider "azurerm" {
  mock_data "azurerm_subscription" {
    defaults = {
      id              = "/subscriptions/00000000-0000-0000-0000-000000000000"
      subscription_id = "00000000-0000-0000-0000-000000000000"
    }
  }

  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-test-rg/providers/Microsoft.OperationalInsights/workspaces/unit-test-law"
    }
  }
}

variables {
  name                 = "unit-test"
  location             = "eastus"
  storage_account_name = "unittestbaselinesa1"
}

run "defender_is_untouched_by_default" {
  command = plan

  assert {
    condition     = length(azurerm_security_center_subscription_pricing.this) == 0
    error_message = "No Defender plan may be set unless defender_plans is given; Standard plans are billed."
  }

  assert {
    condition     = length(azurerm_security_center_contact.this) == 0
    error_message = "The security contact must not be managed unless security_contact is given."
  }
}

run "defender_plans_and_contact_are_created_when_set" {
  command = plan

  variables {
    defender_plans = {
      VirtualMachines = { subplan = "P1" }
      StorageAccounts = { tier = "Free" }
    }

    security_contact = {
      email = "secops@example.com"
    }
  }

  assert {
    condition     = azurerm_security_center_subscription_pricing.this["VirtualMachines"].resource_type == "VirtualMachines"
    error_message = "The map key must be sent as resource_type; the provider otherwise defaults to VirtualMachines."
  }

  assert {
    condition     = azurerm_security_center_subscription_pricing.this["VirtualMachines"].tier == "Standard" && azurerm_security_center_subscription_pricing.this["VirtualMachines"].subplan == "P1"
    error_message = "tier must default to Standard inside an entry, and subplan must be passed through."
  }

  assert {
    condition     = azurerm_security_center_subscription_pricing.this["StorageAccounts"].tier == "Free"
    error_message = "An explicit Free tier must be honoured."
  }

  assert {
    condition = (
      azurerm_security_center_contact.this[0].email == "secops@example.com" &&
      azurerm_security_center_contact.this[0].name == "default1" &&
      azurerm_security_center_contact.this[0].alert_notifications == true &&
      azurerm_security_center_contact.this[0].alerts_to_admins == true &&
      azurerm_security_center_contact.this[0].phone == null
    )
    error_message = "security_contact defaults are name default1 with alert notifications and admin alerts on."
  }
}

run "rejects_invalid_defender_tier" {
  command = plan

  variables {
    defender_plans = {
      VirtualMachines = { tier = "Premium" }
    }
  }

  expect_failures = [var.defender_plans]
}

run "rejects_invalid_security_contact_email" {
  command = plan

  variables {
    security_contact = {
      email = "secops"
    }
  }

  expect_failures = [var.security_contact]
}

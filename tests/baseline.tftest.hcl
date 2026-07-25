# Requires Terraform >= 1.7 for mock_provider. This is a contributor-only
# requirement; the module itself still supports >= 1.5.
#
# Runs entirely offline against a mocked provider - no Azure credentials and no
# network access are needed.

mock_provider "azurerm" {
  # The provider validates target_resource_id against real Azure ID grammars, so
  # the generated placeholder ID is not usable here.
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

run "storage_defaults_are_secure" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.allow_nested_items_to_be_public == false
    error_message = "Blob containers must not be allowed to be made anonymously public by default."
  }

  assert {
    condition     = azurerm_storage_account.this.https_traffic_only_enabled == true
    error_message = "The storage account must reject plaintext HTTP by default."
  }

  assert {
    condition     = azurerm_storage_account.this.min_tls_version == "TLS1_2"
    error_message = "The storage account must require TLS 1.2 by default."
  }
}

run "storage_soft_delete_and_versioning_are_on" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.blob_properties[0].versioning_enabled == true
    error_message = "Blob versioning must be enabled by default."
  }

  assert {
    condition     = azurerm_storage_account.this.blob_properties[0].delete_retention_policy[0].days == 7
    error_message = "Deleted blobs must be retained for 7 days by default."
  }

  assert {
    condition     = azurerm_storage_account.this.blob_properties[0].container_delete_retention_policy[0].days == 7
    error_message = "Deleted containers must be retained for 7 days by default."
  }
}

# The workspace is only worth provisioning if something writes to it. Guard the
# wiring, not just the resource.
run "activity_log_is_wired_to_the_workspace_by_default" {
  # apply, not plan: the workspace ID is only known once the resource exists.
  command = apply

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.activity_log) == 1
    error_message = "The subscription activity log diagnostic setting must be created by default."
  }

  assert {
    condition     = azurerm_monitor_diagnostic_setting.activity_log[0].log_analytics_workspace_id == azurerm_log_analytics_workspace.this.id
    error_message = "The activity log must be routed to the workspace this module creates."
  }

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.activity_log[0].enabled_log) == 8
    error_message = "All eight default activity log categories must be enabled."
  }
}

run "activity_log_can_be_disabled" {
  command = plan

  variables {
    enable_activity_log_diagnostics = false
  }

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.activity_log) == 0
    error_message = "Setting enable_activity_log_diagnostics to false must remove the diagnostic setting."
  }
}

run "tags_reach_every_resource" {
  command = plan

  variables {
    tags = { Environment = "test" }
  }

  assert {
    condition = (
      azurerm_resource_group.this.tags["Environment"] == "test" &&
      azurerm_log_analytics_workspace.this.tags["Environment"] == "test" &&
      azurerm_storage_account.this.tags["Environment"] == "test"
    )
    error_message = "Tags must be applied to all baseline resources."
  }
}

# Premium + GRS validates fine variable-by-variable but is rejected by Azure.
# The precondition has to catch the combination.
run "rejects_premium_with_geo_redundant_replication" {
  command = plan

  variables {
    storage_account_tier             = "Premium"
    storage_account_replication_type = "GRS"
  }

  expect_failures = [azurerm_storage_account.this]
}

run "accepts_premium_with_zone_redundant_replication" {
  command = plan

  variables {
    storage_account_tier             = "Premium"
    storage_account_replication_type = "ZRS"
  }

  assert {
    condition     = azurerm_storage_account.this.account_replication_type == "ZRS"
    error_message = "Premium plus ZRS is a supported combination and must be accepted."
  }
}

run "rejects_invalid_replication_type" {
  command = plan

  variables {
    storage_account_replication_type = "lrs"
  }

  expect_failures = [var.storage_account_replication_type]
}

run "rejects_invalid_storage_account_name" {
  command = plan

  variables {
    storage_account_name = "Invalid-Name"
  }

  expect_failures = [var.storage_account_name]
}

run "rejects_out_of_range_blob_retention" {
  command = plan

  variables {
    storage_blob_retention_in_days = 0
  }

  expect_failures = [var.storage_blob_retention_in_days]
}

run "rejects_out_of_range_log_retention" {
  command = plan

  variables {
    log_retention_in_days = 7
  }

  expect_failures = [var.log_retention_in_days]
}

run "rejects_empty_activity_log_categories" {
  command = plan

  variables {
    activity_log_categories = []
  }

  expect_failures = [var.activity_log_categories]
}

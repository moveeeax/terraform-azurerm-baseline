data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "this" {
  name     = "${var.name}-rg"
  location = var.location

  tags = var.tags
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.name}-law"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_in_days

  tags = var.tags
}

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type

  # Secure-by-default transport and access settings. Without these the provider
  # falls back to Azure's permissive defaults - in particular
  # allow_nested_items_to_be_public defaults to true, which lets anyone with
  # write access to the account expose blob containers anonymously.
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = var.storage_shared_access_key_enabled
  public_network_access_enabled   = var.storage_public_network_access_enabled

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = var.storage_blob_retention_in_days
    }

    container_delete_retention_policy {
      days = var.storage_blob_retention_in_days
    }
  }

  tags = var.tags

  lifecycle {
    # account_tier and account_replication_type validate independently, but Azure
    # only supports LRS and ZRS on the Premium tier. Catch the invalid pairing at
    # plan time instead of failing part-way through an apply.
    precondition {
      condition = var.storage_account_tier != "Premium" || contains(
        ["LRS", "ZRS"], var.storage_account_replication_type
      )
      error_message = "The Premium storage_account_tier only supports LRS or ZRS replication."
    }
  }
}

# The workspace above is only useful once something writes to it. Route the
# subscription activity log into it so the "centralized logging" half of this
# baseline is actually wired up rather than just provisioned.
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  count = var.enable_activity_log_diagnostics ? 1 : 0

  name                       = "${var.name}-activity-log"
  target_resource_id         = data.azurerm_subscription.current.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  dynamic "enabled_log" {
    for_each = toset(var.activity_log_categories)

    content {
      category = enabled_log.value
    }
  }
}

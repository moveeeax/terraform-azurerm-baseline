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

  tags = var.tags
}

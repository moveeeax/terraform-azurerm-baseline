# terraform-azurerm-baseline

Terraform module that provisions a minimal [Azure](https://azure.microsoft.com/)
landing-zone baseline: a resource group, a Log Analytics workspace for
centralized logging, and a storage account for diagnostics or state. It is a
composition module that gives new workloads a consistent starting point.

## Usage

```hcl
module "baseline" {
  source = "github.com/moveeeax/terraform-azurerm-baseline"

  name                 = "platform"
  location             = "eastus"
  storage_account_name = "platformbaselinesa01"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| azurerm   | >= 3.0   |

## Inputs

| Name                               | Description                                                     | Type          | Default       | Required |
|------------------------------------|-----------------------------------------------------------------|---------------|---------------|:--------:|
| `name`                             | Base name used to derive resource names.                        | `string`      | n/a           |   yes    |
| `location`                         | Azure region in which to create the resources.                  | `string`      | n/a           |   yes    |
| `storage_account_name`             | Globally unique storage account name (3-24 lowercase alnum).    | `string`      | n/a           |   yes    |
| `log_analytics_sku`                | SKU of the Log Analytics workspace.                             | `string`      | `"PerGB2018"` |    no    |
| `log_retention_in_days`            | Days to retain data in the workspace (30-730).                  | `number`      | `30`          |    no    |
| `storage_account_tier`             | Performance tier: Standard or Premium.                          | `string`      | `"Standard"`  |    no    |
| `storage_account_replication_type` | Replication type of the storage account.                        | `string`      | `"LRS"`       |    no    |
| `tags`                             | Map of tags applied to all baseline resources.                  | `map(string)` | `{}`          |    no    |

## Outputs

| Name                         | Description                              |
|------------------------------|------------------------------------------|
| `resource_group_name`        | Name of the created resource group.      |
| `resource_group_id`          | ID of the created resource group.        |
| `log_analytics_workspace_id` | ID of the Log Analytics workspace.       |
| `storage_account_id`         | ID of the storage account.               |
| `storage_account_name`       | Name of the storage account.             |

## License

[MIT](LICENSE)

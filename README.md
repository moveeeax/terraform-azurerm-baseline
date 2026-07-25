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

## Secure defaults

The module is opinionated so that an unconfigured consumer still lands on a safe
baseline:

- The storage account refuses plaintext HTTP, requires TLS 1.2, and **cannot**
  have its blob containers made anonymously public
  (`allow_nested_items_to_be_public = false`). The provider default for that last
  setting is `true`, so leaving it unset is what makes storage accounts leak.
- Blob versioning is on, and deleted blobs and containers are soft-deleted with a
  7 day recovery window.
- The subscription activity log is streamed into the Log Analytics workspace.
  Without this the workspace is provisioned but nothing ever writes to it, so the
  "centralized logging" half of the baseline does nothing. Disable with
  `enable_activity_log_diagnostics = false`.
- `Premium` + geo-redundant replication is rejected at plan time rather than
  failing part-way through an apply; Azure only supports `LRS` and `ZRS` on the
  Premium tier.

## Requirements

| Name      | Version            |
|-----------|--------------------|
| terraform | >= 1.5             |
| azurerm   | >= 3.114.0, < 5.0  |

`azurerm` 3.114.0 is the first release that exposes
`azurerm_storage_account.https_traffic_only_enabled`; the module does not build
on anything older. Both 3.114.0 and the 4.x line are supported.

## Inputs

| Name                               | Description                                                     | Type          | Default       | Required |
|------------------------------------|-----------------------------------------------------------------|---------------|---------------|:--------:|
| `name`                             | Base name used to derive resource names.                        | `string`      | n/a           |   yes    |
| `location`                         | Azure region in which to create the resources.                  | `string`      | n/a           |   yes    |
| `storage_account_name`             | Globally unique storage account name (3-24 lowercase alnum).    | `string`      | n/a           |   yes    |
| `log_analytics_sku`                | SKU of the Log Analytics workspace.                             | `string`      | `"PerGB2018"` |    no    |
| `log_retention_in_days`            | Days to retain data in the workspace (30-730).                  | `number`      | `30`          |    no    |
| `storage_account_tier`             | Performance tier: Standard or Premium.                          | `string`      | `"Standard"`  |    no    |
| `storage_account_replication_type` | Replication type: LRS, GRS, RAGRS, ZRS, GZRS or RAGZRS.         | `string`      | `"LRS"`       |    no    |
| `storage_shared_access_key_enabled`| Allow shared access key (account key) auth on the storage account. | `bool`     | `true`        |    no    |
| `storage_public_network_access_enabled` | Whether the storage account is reachable from the internet. | `bool`      | `true`        |    no    |
| `storage_blob_retention_in_days`   | Soft-delete window for blobs and containers (1-365).            | `number`      | `7`           |    no    |
| `enable_activity_log_diagnostics`  | Stream the subscription activity log into the workspace.        | `bool`        | `true`        |    no    |
| `activity_log_categories`          | Activity log categories to forward.                             | `list(string)`| all 8 categories |  no   |
| `tags`                             | Map of tags applied to all baseline resources.                  | `map(string)` | `{}`          |    no    |

## Outputs

| Name                         | Description                              |
|------------------------------|------------------------------------------|
| `resource_group_name`        | Name of the created resource group.      |
| `resource_group_id`          | ID of the created resource group.        |
| `log_analytics_workspace_id` | ID of the Log Analytics workspace.       |
| `storage_account_id`         | ID of the storage account.               |
| `storage_account_name`       | Name of the storage account.             |
| `activity_log_diagnostic_setting_id` | ID of the activity log diagnostic setting, or `null` when disabled. |

## Development

```sh
terraform init -backend=false
terraform validate
terraform test      # needs Terraform >= 1.7; runs offline against a mocked provider
tflint --recursive
```

## License

[MIT](LICENSE)

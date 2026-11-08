# terraform-azurerm-baseline

Terraform module that provisions a minimal [Azure](https://azure.microsoft.com/)
landing-zone baseline: a resource group, a Log Analytics workspace for
centralized logging, and a storage account for diagnostics or state. It is a
composition module that gives new workloads a consistent starting point.

## Usage

```hcl
module "baseline" {
  source = "github.com/moveeeax/terraform-azurerm-baseline?ref=v1.0.0"

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

## Defender for Cloud

`defender_plans` and `security_contact` are off by default. Both act on the
whole subscription, not only on what this module creates:

- A `Standard` plan covers every resource of that type in the subscription and is
  billed per protected resource. Check
  [Defender for Cloud pricing](https://azure.microsoft.com/pricing/details/defender-for-cloud/)
  before turning one on.
- If a plan is already above `Free`, or a contact with the same `name` already
  exists, the provider refuses to create it and asks for a `terraform import`.
- Removing an entry from `defender_plans` sets that plan back to `Free`; it does
  not restore whatever tier it had before.

The map key is the provider's `resource_type` (`VirtualMachines`,
`StorageAccounts`, `KeyVaults`, `Arm`, `CloudPosture`, ...); the accepted values
depend on your `azurerm` version and are checked by the provider.

```hcl
module "baseline" {
  # source, name, location, storage_account_name as above

  defender_plans = {
    CloudPosture    = { tier = "Free" }
    Arm             = {}                    # tier defaults to Standard
    VirtualMachines = { subplan = "P1" }
  }

  security_contact = {
    email = "secops@example.com"
    # alert_notifications and alerts_to_admins default to true
  }
}
```

Recommended for an audited subscription: set `security_contact`, and enable the
`Standard` plans for the resource types you actually run.

## Requirements

| Name      | Version            |
|-----------|--------------------|
| terraform | >= 1.5             |
| azurerm   | >= 3.114.0, < 6.0  |

`azurerm` 3.114.0 is the first release that exposes
`azurerm_storage_account.https_traffic_only_enabled`; the module does not build
on anything older. The 3.x (from 3.114.0), 4.x and 5.x lines are supported; CI
runs against the latest 5.x release. 6.x is excluded until it has been tested.

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
| `defender_plans`                   | Defender for Cloud plans keyed by resource type (`tier`, `subplan`). Subscription-wide. | `map(object)` | `{}` | no |
| `security_contact`                 | Defender for Cloud security contact (`email`, `phone`, `alert_notifications`, `alerts_to_admins`, `name`). | `object` | `null` | no |
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
| `defender_plan_ids`          | IDs of the Defender for Cloud pricing settings, keyed by resource type. |
| `security_contact_id`        | ID of the security contact, or `null` when not managed. |

## Development

```sh
terraform init -backend=false
terraform validate
terraform test      # needs Terraform >= 1.7; runs offline against a mocked provider
tflint --recursive
```

## License

[MIT](LICENSE)

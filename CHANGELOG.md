# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.2.0] - 2026-11-08

### Added

- `defender_plans`: Microsoft Defender for Cloud plans per resource type
  (`azurerm_security_center_subscription_pricing`), with `tier` (`Standard` or
  `Free`) and an optional `subplan`. Defaults to `{}`: no plan is set.
- `security_contact`: the subscription's Defender for Cloud security contact
  (`azurerm_security_center_contact`). Defaults to `null`: no contact is managed.
- `defender_plan_ids` and `security_contact_id` outputs.
- `budget`: a subscription consumption budget
  (`azurerm_consumption_budget_subscription`) that emails `contact_emails` when
  actual cost reaches each of `thresholds` (default 80 and 100 percent of
  `amount`). Defaults to `null`: no budget is created.
- `budget_id` output.

## [1.1.0] - 2026-11-05

### Changed

- Allow `azurerm` 5.x and refresh CI.

## [1.0.0] - 2026-07-26

Initial release (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-azurerm-baseline/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/moveeeax/terraform-azurerm-baseline/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/moveeeax/terraform-azurerm-baseline/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/moveeeax/terraform-azurerm-baseline/releases/tag/v1.0.0

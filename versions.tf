terraform {
  # The module itself works on Terraform >= 1.5. The test suite under tests/
  # additionally needs >= 1.7 for mock_provider, but that is a contributor-only
  # requirement and deliberately not encoded here.
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # 3.114.0 is the first release exposing
      # azurerm_storage_account.https_traffic_only_enabled (the rename of
      # enable_https_traffic_only). Verified empirically: 3.113.0 fails to
      # validate this module, 3.114.0 and 4.81.0 both succeed.
      version = ">= 3.114.0, < 5.0"
    }
  }
}

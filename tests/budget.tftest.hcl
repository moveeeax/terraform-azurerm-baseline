# Subscription budget with email alerts. Off unless budget is set.
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

run "no_budget_by_default" {
  command = plan

  assert {
    condition     = length(azurerm_consumption_budget_subscription.this) == 0
    error_message = "No budget may be created unless budget is set."
  }
}

run "budget_defaults" {
  command = plan

  variables {
    budget = {
      amount         = 500
      contact_emails = ["finops@example.com"]
    }
  }

  assert {
    condition = (
      azurerm_consumption_budget_subscription.this[0].name == "unit-test-budget" &&
      azurerm_consumption_budget_subscription.this[0].subscription_id == "/subscriptions/00000000-0000-0000-0000-000000000000" &&
      azurerm_consumption_budget_subscription.this[0].amount == 500 &&
      azurerm_consumption_budget_subscription.this[0].time_grain == "Monthly"
    )
    error_message = "The budget must default to a monthly budget named <name>-budget on the current subscription."
  }

  assert {
    condition     = toset([for n in azurerm_consumption_budget_subscription.this[0].notification : n.threshold]) == toset([80, 100])
    error_message = "Default thresholds must be 80 and 100 percent."
  }

  assert {
    condition = alltrue([
      for n in azurerm_consumption_budget_subscription.this[0].notification :
      n.contact_emails == tolist(["finops@example.com"]) && n.operator == "GreaterThanOrEqualTo" && n.threshold_type == "Actual"
    ])
    error_message = "Every notification must mail contact_emails on actual cost."
  }

  assert {
    condition     = can(regex("^[0-9]{4}-[0-9]{2}-01T00:00:00Z$", azurerm_consumption_budget_subscription.this[0].time_period[0].start_date))
    error_message = "A null start_date must resolve to the first of the current month."
  }
}

run "budget_explicit_values" {
  command = plan

  variables {
    budget = {
      name           = "platform-quarterly"
      amount         = 3000
      time_grain     = "Quarterly"
      thresholds     = [50, 90, 120]
      start_date     = "2026-10-01T00:00:00Z"
      contact_emails = ["a@example.com", "b@example.com"]
    }
  }

  assert {
    condition = (
      azurerm_consumption_budget_subscription.this[0].name == "platform-quarterly" &&
      azurerm_consumption_budget_subscription.this[0].time_grain == "Quarterly" &&
      azurerm_consumption_budget_subscription.this[0].time_period[0].start_date == "2026-10-01T00:00:00Z" &&
      length(azurerm_consumption_budget_subscription.this[0].notification) == 3
    )
    error_message = "Explicit budget values must be passed through."
  }
}

run "rejects_budget_without_contacts" {
  command = plan

  variables {
    budget = {
      amount         = 500
      contact_emails = []
    }
  }

  expect_failures = [var.budget]
}

run "rejects_invalid_time_grain" {
  command = plan

  variables {
    budget = {
      amount         = 500
      contact_emails = ["finops@example.com"]
      time_grain     = "Weekly"
    }
  }

  expect_failures = [var.budget]
}

run "rejects_too_many_thresholds" {
  command = plan

  variables {
    budget = {
      amount         = 500
      contact_emails = ["finops@example.com"]
      thresholds     = [10, 20, 30, 40, 50, 60]
    }
  }

  expect_failures = [var.budget]
}

run "rejects_start_date_not_on_first_of_month" {
  command = plan

  variables {
    budget = {
      amount         = 500
      contact_emails = ["finops@example.com"]
      start_date     = "2026-11-15T00:00:00Z"
    }
  }

  expect_failures = [var.budget]
}

run "rejects_non_positive_amount" {
  command = plan

  variables {
    budget = {
      amount         = 0
      contact_emails = ["finops@example.com"]
    }
  }

  expect_failures = [var.budget]
}

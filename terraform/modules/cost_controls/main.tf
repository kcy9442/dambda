locals {
  enabled = var.enable_cost_controls && var.alert_email != ""
}

resource "terraform_data" "cost_control_configuration" {
  count = var.enable_cost_controls ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.alert_email != ""
      error_message = "cost_alert_email must be set when enable_cost_controls is true."
    }
  }
}

resource "aws_budgets_budget" "monthly" {
  count = local.enabled ? 1 : 0

  depends_on = [terraform_data.cost_control_configuration]

  name         = "${var.region_name}-monthly-cost-budget"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}

resource "aws_ce_anomaly_monitor" "services" {
  count = local.enabled ? 1 : 0

  depends_on = [terraform_data.cost_control_configuration]

  name              = "${var.region_name}-aws-services"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "daily" {
  count = local.enabled ? 1 : 0

  name      = "${var.region_name}-daily-cost-anomalies"
  frequency = "DAILY"

  monitor_arn_list = [aws_ce_anomaly_monitor.services[0].arn]

  subscriber {
    type    = "EMAIL"
    address = var.alert_email
  }

  threshold_expression {
    and {
      dimension {
        key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
        values        = [tostring(var.anomaly_threshold_usd)]
        match_options = ["GREATER_THAN_OR_EQUAL"]
      }
    }
  }
}

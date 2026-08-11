variable "region_name" {
  type = string
}

variable "enable_cost_controls" {
  type    = bool
  default = false
}

variable "alert_email" {
  type    = string
  default = ""
}

variable "monthly_budget_usd" {
  type    = number
  default = 25
}

variable "anomaly_threshold_usd" {
  type    = number
  default = 5
}

variable "enable_anomaly_detection" {
  type    = bool
  default = false
}

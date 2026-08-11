output "prometheus_workspace_arn" {
  value = try(aws_prometheus_workspace.main[0].arn, null)
}

output "prometheus_remote_write_endpoint" {
  value = try(aws_prometheus_workspace.main[0].prometheus_endpoint, null)
}

output "grafana_workspace_endpoint" {
  value = try(aws_grafana_workspace.main[0].endpoint, null)
}

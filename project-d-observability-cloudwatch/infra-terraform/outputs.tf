output "dashboard_url" {
  value = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.main.dashboard_name
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "log_group_name" {
  value = var.log_group_name
}

output "alb_5xx_alarm_name" {
  value = aws_cloudwatch_metric_alarm.alb_5xx.alarm_name
}

output "canary_name" {
  value = var.canary_endpoint != "" ? aws_synthetics_canary.heartbeat[0].name : null
}

output "canary_bucket" {
  value = var.canary_endpoint != "" ? aws_s3_bucket.canary[0].id : null
}

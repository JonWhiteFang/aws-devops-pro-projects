resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "app-observability"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_name]
          ]
          period = 60
          stat   = "Sum"
          title  = "ALB 5xx Errors"
          region = var.region
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster, "ServiceName", var.ecs_service]
          ]
          period = 60
          stat   = "Average"
          title  = "ECS CPU Utilization"
          region = var.region
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_cluster, "ServiceName", var.ecs_service]
          ]
          period = 60
          stat   = "Average"
          title  = "ECS Memory Utilization"
          region = var.region
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["DemoApp", "ErrorCount", "Service", "api"]
          ]
          period = 60
          stat   = "Sum"
          title  = "Application Errors (Custom Metric)"
          region = var.region
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_name],
            [".", "TargetResponseTime", ".", ".", { stat = "p99" }]
          ]
          period = 60
          title  = "Request Count & P99 Latency"
          region = var.region
          yAxis = {
            left  = { min = 0 }
            right = { min = 0 }
          }
        }
      }
    ]
  })
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "app-alerts"
}

# Basic 5xx alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "ALB-5xx-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "High 5xx errors on ALB"
  dimensions = {
    LoadBalancer = var.alb_name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# CPU alarm
resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "ECS-CPU-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "High CPU utilization on ECS service"
  dimensions = {
    ClusterName = var.ecs_cluster
    ServiceName = var.ecs_service
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}

# Composite alarm - triggers when BOTH 5xx AND CPU are in alarm
resource "aws_cloudwatch_composite_alarm" "critical" {
  alarm_name = "Critical-Service-Degradation"
  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.alb_5xx.alarm_name}) AND ALARM(${aws_cloudwatch_metric_alarm.ecs_cpu.alarm_name})"

  alarm_description = "Critical: Both 5xx errors and high CPU detected"
  alarm_actions     = [aws_sns_topic.alerts.arn]
}

# Anomaly detection alarm
resource "aws_cloudwatch_metric_alarm" "request_anomaly" {
  alarm_name          = "Request-Count-Anomaly"
  comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
  evaluation_periods  = 2
  threshold_metric_id = "ad1"
  alarm_description   = "Request count anomaly detected"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  metric_query {
    id          = "m1"
    return_data = true
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 300
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_name
      }
    }
  }

  metric_query {
    id          = "ad1"
    expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
    label       = "RequestCount (expected)"
    return_data = true
  }
}

# Log metric filter for application errors
resource "aws_cloudwatch_log_metric_filter" "errors" {
  name           = "ApplicationErrors"
  pattern        = "ERROR"
  log_group_name = var.log_group_name

  metric_transformation {
    name      = "ErrorCount"
    namespace = "DemoApp"
    value     = "1"
  }
}

# Log metric filter for latency extraction
resource "aws_cloudwatch_log_metric_filter" "latency" {
  name           = "RequestLatency"
  pattern        = "[timestamp, requestId, level, latency_label=\"latency=\", latency_value]"
  log_group_name = var.log_group_name

  metric_transformation {
    name      = "Latency"
    namespace = "DemoApp"
    value     = "$latency_value"
    unit      = "Milliseconds"
  }
}

# Outputs
output "dashboard_url" {
  value = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

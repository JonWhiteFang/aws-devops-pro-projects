output "alb_dns_a" {
  description = "ALB DNS name in region A"
  value       = aws_lb.a.dns_name
}

output "alb_dns_b" {
  description = "ALB DNS name in region B"
  value       = aws_lb.b.dns_name
}

output "app_url_failover" {
  description = "Application URL (failover routing)"
  value       = "http://app.${var.domain_name}"
}

output "app_url_latency" {
  description = "Application URL (latency routing)"
  value       = "http://app-latency.${var.domain_name}"
}

output "dynamodb_table_name" {
  description = "DynamoDB Global Table name"
  value       = aws_dynamodb_table.app.name
}

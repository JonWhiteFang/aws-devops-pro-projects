output "config_recorder_name" {
  description = "Name of the AWS Config recorder"
  value       = aws_config_configuration_recorder.rec.name
}

output "config_bucket" {
  description = "S3 bucket for Config logs"
  value       = aws_s3_bucket.config_logs.bucket
}

output "lambda_function_name" {
  description = "Name of the custom Config rule Lambda function"
  value       = aws_lambda_function.required_tags.function_name
}

output "ssm_document_name" {
  description = "Name of the SSM Automation document for remediation"
  value       = aws_ssm_document.tag_missing.name
}

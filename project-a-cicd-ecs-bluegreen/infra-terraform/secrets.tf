# Secrets Manager for application secrets
resource "aws_secretsmanager_secret" "app" {
  name                    = "${var.project}-app-secrets"
  recovery_window_in_days = 0 # For demo; use 7-30 in production
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({
    API_KEY     = "change-me-in-console"
    DB_PASSWORD = "change-me-in-console"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# IAM policy for ECS task to read secrets
resource "aws_iam_role_policy" "task_secrets" {
  role = aws_iam_role.ecs_task_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = aws_secretsmanager_secret.app.arn
    }]
  })
}

# Output for reference
output "secrets_arn" {
  description = "Secrets Manager ARN for application secrets"
  value       = aws_secretsmanager_secret.app.arn
}

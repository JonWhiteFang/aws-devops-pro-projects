# AWS Backup vault in primary region
resource "aws_backup_vault" "primary" {
  provider = aws.a
  name     = "${var.project}-backup-vault"
}

# AWS Backup vault in secondary region (for cross-region copy)
resource "aws_backup_vault" "secondary" {
  provider = aws.b
  name     = "${var.project}-backup-vault"
}

# IAM role for AWS Backup
resource "aws_iam_role" "backup" {
  name = "${var.project}-backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restores" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Backup plan with cross-region copy
resource "aws_backup_plan" "main" {
  provider = aws.a
  name     = "${var.project}-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = "cron(0 5 ? * * *)" # Daily at 5 AM UTC

    lifecycle {
      delete_after = 30
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.secondary.arn
      lifecycle {
        delete_after = 30
      }
    }
  }

  rule {
    rule_name         = "weekly-backup"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = "cron(0 5 ? * SUN *)" # Weekly on Sunday

    lifecycle {
      delete_after = 90
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.secondary.arn
      lifecycle {
        delete_after = 90
      }
    }
  }
}

# Backup selection - DynamoDB table
resource "aws_backup_selection" "dynamodb" {
  provider     = aws.a
  name         = "${var.project}-dynamodb"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = [
    aws_dynamodb_table.app.arn
  ]
}

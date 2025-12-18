variable "region" {
  type    = string
  default = "eu-west-1"
}

resource "aws_s3_bucket" "config_logs" {
  bucket        = "config-logs-${random_id.sfx.hex}"
  force_destroy = true
}

resource "random_id" "sfx" {
  byte_length = 4
}

data "aws_caller_identity" "current" {}

# Config Recorder
resource "aws_config_configuration_recorder" "rec" {
  name     = "default"
  role_arn = aws_iam_role.config.arn
  recording_group {
    all_supported                 = true
    include_global_resource_types = false
  }
}

resource "aws_config_delivery_channel" "chan" {
  name           = "default"
  s3_bucket_name = aws_s3_bucket.config_logs.bucket
  depends_on     = [aws_config_configuration_recorder.rec]
}

resource "aws_config_configuration_recorder_status" "status" {
  name       = aws_config_configuration_recorder.rec.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.chan]
}

# Config IAM Role
resource "aws_iam_role" "config" {
  name = "aws-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config_managed" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_role_policy" "config_iam" {
  role = aws_iam_role.config.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["iam:Get*", "iam:List*"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "config_s3" {
  role = aws_iam_role.config.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:GetBucketAcl"]
      Resource = [aws_s3_bucket.config_logs.arn, "${aws_s3_bucket.config_logs.arn}/*"]
    }]
  })
}

# Managed Rules
resource "aws_config_config_rule" "s3_public_read_prohibited" {
  name = "s3-bucket-public-read-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
  depends_on = [aws_config_configuration_recorder_status.status]
}

resource "aws_config_config_rule" "encrypted_volumes" {
  name = "encrypted-volumes"
  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
  depends_on = [aws_config_configuration_recorder_status.status]
}

resource "aws_config_config_rule" "rds_encryption_enabled" {
  name = "rds-storage-encrypted"
  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }
  depends_on = [aws_config_configuration_recorder_status.status]
}

# Custom Rule - Required Tags
resource "aws_config_config_rule" "required_tags" {
  name = "required-tags"
  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.required_tags.arn
    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }
  }
  scope {
    compliance_resource_types = ["AWS::EC2::Instance"]
  }
  input_parameters = jsonencode({
    tag1Key = "Owner"
    tag2Key = "Environment"
  })
  depends_on = [
    aws_config_configuration_recorder_status.status,
    aws_lambda_permission.config
  ]
}

# Lambda IAM Role
resource "aws_iam_role" "lambda" {
  name = "config-custom-rule-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_config" {
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["config:PutEvaluations"]
      Resource = "*"
    }]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_required_tags.py"
  output_path = "${path.module}/lambda_required_tags.zip"
}

resource "aws_lambda_function" "required_tags" {
  function_name = "config-required-tags"
  role          = aws_iam_role.lambda.arn
  handler       = "lambda_required_tags.lambda_handler"
  runtime       = "python3.11"
  filename      = data.archive_file.lambda_zip.output_path
  timeout       = 60

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# Lambda permission for Config to invoke
resource "aws_lambda_permission" "config" {
  statement_id  = "AllowConfigInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.required_tags.function_name
  principal     = "config.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
}

# SSM Automation Role for Remediation
resource "aws_iam_role" "ssm_automation" {
  name = "ssm-automation-remediator"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ssm.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ssm_inline" {
  role = aws_iam_role.ssm_automation.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:CreateTags", "ec2:DescribeTags"]
        Resource = "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

resource "aws_ssm_document" "tag_missing" {
  name          = "TagMissingOwnerEnvironment"
  document_type = "Automation"
  content = jsonencode({
    schemaVersion = "0.3"
    description   = "Add required tags to EC2 instance"
    assumeRole    = "{{ AutomationAssumeRole }}"
    parameters = {
      InstanceId = {
        type        = "String"
        description = "EC2 Instance ID"
      }
      AutomationAssumeRole = {
        type        = "String"
        default     = aws_iam_role.ssm_automation.arn
        description = "IAM role for automation"
      }
    }
    mainSteps = [{
      name   = "AddTags"
      action = "aws:executeAwsApi"
      inputs = {
        Service = "EC2"
        Api     = "CreateTags"
        Resources = ["{{ InstanceId }}"]
        Tags = [
          { Key = "Owner", Value = "AutoFix" },
          { Key = "Environment", Value = "Dev" }
        ]
      }
    }]
  })
}

# Config Remediation Configuration
resource "aws_config_remediation_configuration" "required_tags" {
  config_rule_name = aws_config_config_rule.required_tags.name
  target_type      = "SSM_DOCUMENT"
  target_id        = aws_ssm_document.tag_missing.name

  parameter {
    name         = "InstanceId"
    resource_value = "RESOURCE_ID"
  }

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.ssm_automation.arn
  }

  automatic                  = true
  maximum_automatic_attempts = 3
  retry_attempt_seconds      = 60
}

# Outputs
output "config_recorder_name" {
  value = aws_config_configuration_recorder.rec.name
}

output "config_bucket" {
  value = aws_s3_bucket.config_logs.bucket
}

output "lambda_function_name" {
  value = aws_lambda_function.required_tags.function_name
}

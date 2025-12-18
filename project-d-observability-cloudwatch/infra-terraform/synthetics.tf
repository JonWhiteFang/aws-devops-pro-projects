variable "canary_endpoint" {
  type        = string
  default     = ""
  description = "Endpoint URL for Synthetics canary (leave empty to skip canary creation)"
}

# S3 bucket for canary artifacts
resource "aws_s3_bucket" "canary" {
  count         = var.canary_endpoint != "" ? 1 : 0
  bucket        = "synthetics-canary-${random_id.canary[0].hex}"
  force_destroy = true
}

resource "random_id" "canary" {
  count       = var.canary_endpoint != "" ? 1 : 0
  byte_length = 4
}

# IAM role for Synthetics
resource "aws_iam_role" "canary" {
  count = var.canary_endpoint != "" ? 1 : 0
  name  = "synthetics-canary-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "canary" {
  count = var.canary_endpoint != "" ? 1 : 0
  role  = aws_iam_role.canary[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "${aws_s3_bucket.canary[0].arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetBucketLocation"]
        Resource = aws_s3_bucket.canary[0].arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["cloudwatch:PutMetricData"]
        Resource = "*"
        Condition = {
          StringEquals = { "cloudwatch:namespace" = "CloudWatchSynthetics" }
        }
      }
    ]
  })
}

# Synthetics Canary
resource "aws_synthetics_canary" "heartbeat" {
  count                = var.canary_endpoint != "" ? 1 : 0
  name                 = "app-heartbeat"
  artifact_s3_location = "s3://${aws_s3_bucket.canary[0].id}/"
  execution_role_arn   = aws_iam_role.canary[0].arn
  runtime_version      = "syn-nodejs-puppeteer-9.1"
  handler              = "heartbeat.handler"
  start_canary         = true

  schedule {
    expression = "rate(5 minutes)"
  }

  zip_file = data.archive_file.canary[0].output_path
}

data "archive_file" "canary" {
  count       = var.canary_endpoint != "" ? 1 : 0
  type        = "zip"
  output_path = "${path.module}/canary.zip"
  source {
    content = <<-EOF
      const synthetics = require('Synthetics');
      const log = require('SyntheticsLogger');

      const heartbeat = async function () {
        const page = await synthetics.getPage();
        const response = await page.goto('${var.canary_endpoint}', {
          waitUntil: 'domcontentloaded',
          timeout: 30000
        });
        if (response.status() !== 200) {
          throw new Error('Failed to load page: ' + response.status());
        }
        log.info('Page loaded successfully');
      };

      exports.handler = async () => {
        return await heartbeat();
      };
    EOF
    filename = "nodejs/node_modules/heartbeat.js"
  }
}

# Alarm for canary failures
resource "aws_cloudwatch_metric_alarm" "canary_failed" {
  count               = var.canary_endpoint != "" ? 1 : 0
  alarm_name          = "Canary-Failed"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "SuccessPercent"
  namespace           = "CloudWatchSynthetics"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "Synthetics canary success rate dropped"
  dimensions = {
    CanaryName = aws_synthetics_canary.heartbeat[0].name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}

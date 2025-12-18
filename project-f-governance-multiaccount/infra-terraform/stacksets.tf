# IAM roles for StackSets
resource "aws_iam_role" "stackset_admin" {
  name = "AWSCloudFormationStackSetAdministrationRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudformation.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "stackset_admin" {
  role = aws_iam_role.stackset_admin.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = "arn:aws:iam::*:role/AWSCloudFormationStackSetExecutionRole"
    }]
  })
}

# Example StackSet - Deploy CloudWatch alarm baseline to all accounts
resource "aws_cloudformation_stack_set" "cloudwatch_baseline" {
  name             = "cloudwatch-alarm-baseline"
  permission_model = "SERVICE_MANAGED"

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  template_body = jsonencode({
    AWSTemplateFormatVersion = "2010-09-09"
    Description              = "Baseline CloudWatch alarms for all accounts"
    
    Parameters = {
      AlertEmail = {
        Type        = "String"
        Description = "Email for alarm notifications"
        Default     = "alerts@example.com"
      }
    }

    Resources = {
      AlertTopic = {
        Type = "AWS::SNS::Topic"
        Properties = {
          TopicName = "account-alerts"
          Subscription = [{
            Protocol = "email"
            Endpoint = { Ref = "AlertEmail" }
          }]
        }
      }

      RootAccountUsageAlarm = {
        Type = "AWS::CloudWatch::Alarm"
        Properties = {
          AlarmName          = "RootAccountUsage"
          AlarmDescription   = "Alert when root account is used"
          MetricName         = "RootAccountUsage"
          Namespace          = "CloudTrailMetrics"
          Statistic          = "Sum"
          Period             = 300
          EvaluationPeriods  = 1
          Threshold          = 1
          ComparisonOperator = "GreaterThanOrEqualToThreshold"
          AlarmActions       = [{ Ref = "AlertTopic" }]
          TreatMissingData   = "notBreaching"
        }
      }

      UnauthorizedAPICallsAlarm = {
        Type = "AWS::CloudWatch::Alarm"
        Properties = {
          AlarmName          = "UnauthorizedAPICalls"
          AlarmDescription   = "Alert on unauthorized API calls"
          MetricName         = "UnauthorizedAPICalls"
          Namespace          = "CloudTrailMetrics"
          Statistic          = "Sum"
          Period             = 300
          EvaluationPeriods  = 1
          Threshold          = 10
          ComparisonOperator = "GreaterThanOrEqualToThreshold"
          AlarmActions       = [{ Ref = "AlertTopic" }]
          TreatMissingData   = "notBreaching"
        }
      }
    }

    Outputs = {
      AlertTopicArn = {
        Value       = { Ref = "AlertTopic" }
        Description = "SNS Topic ARN for alerts"
      }
    }
  })

  lifecycle {
    ignore_changes = [administration_role_arn]
  }
}

# Deploy to all accounts in organization
resource "aws_cloudformation_stack_set_instance" "all_accounts" {
  stack_set_name = aws_cloudformation_stack_set.cloudwatch_baseline.name
  
  deployment_targets {
    organizational_unit_ids = [data.aws_organizations_organization.org.roots[0].id]
  }

  region = var.region
}

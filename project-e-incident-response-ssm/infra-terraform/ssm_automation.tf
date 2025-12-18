data "aws_caller_identity" "current" {}

# SSM Automation Role for ECS
resource "aws_iam_role" "automation_ecs" {
  name = "automation-ecs-recovery"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ssm.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "automation_ecs" {
  role = aws_iam_role.automation_ecs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecs:UpdateService", "ecs:DescribeServices"]
        Resource = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${var.ecs_cluster}/${var.ecs_service}"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

# SSM Automation Role for EC2
resource "aws_iam_role" "automation_ec2" {
  name = "automation-ec2-recovery"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ssm.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "automation_ec2" {
  role = aws_iam_role.automation_ec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:StartInstances", "ec2:StopInstances", "ec2:DescribeInstances", "ec2:CreateSnapshot", "ec2:DescribeVolumes"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

# Runbook: Restart ECS Service
resource "aws_ssm_document" "restart_ecs" {
  name          = "RestartEcsService"
  document_type = "Automation"
  content = jsonencode({
    schemaVersion = "0.3"
    description   = "Force new deployment to restart ECS tasks"
    assumeRole    = "{{ AutomationAssumeRole }}"
    parameters = {
      Cluster = {
        type        = "String"
        description = "ECS Cluster name"
        default     = var.ecs_cluster
      }
      Service = {
        type        = "String"
        description = "ECS Service name"
        default     = var.ecs_service
      }
      AutomationAssumeRole = {
        type    = "String"
        default = aws_iam_role.automation_ecs.arn
      }
    }
    mainSteps = [{
      name   = "RestartService"
      action = "aws:executeAwsApi"
      inputs = {
        Service            = "ECS"
        Api                = "UpdateService"
        cluster            = "{{ Cluster }}"
        service            = "{{ Service }}"
        forceNewDeployment = true
      }
    }]
  })
}

# Runbook: Recover EC2 Instance
resource "aws_ssm_document" "recover_ec2" {
  name          = "RecoverEC2Instance"
  document_type = "Automation"
  content = jsonencode({
    schemaVersion = "0.3"
    description   = "Stop and start EC2 instance to recover"
    assumeRole    = "{{ AutomationAssumeRole }}"
    parameters = {
      InstanceId = {
        type        = "String"
        description = "EC2 Instance ID"
      }
      AutomationAssumeRole = {
        type    = "String"
        default = aws_iam_role.automation_ec2.arn
      }
    }
    mainSteps = [
      {
        name   = "StopInstance"
        action = "aws:executeAwsApi"
        inputs = {
          Service     = "EC2"
          Api         = "StopInstances"
          InstanceIds = ["{{ InstanceId }}"]
        }
      },
      {
        name           = "WaitForStop"
        action         = "aws:waitForAwsResourceProperty"
        timeoutSeconds = 300
        inputs = {
          Service      = "EC2"
          Api          = "DescribeInstances"
          InstanceIds  = ["{{ InstanceId }}"]
          PropertySelector = "$.Reservations[0].Instances[0].State.Name"
          DesiredValues    = ["stopped"]
        }
      },
      {
        name   = "StartInstance"
        action = "aws:executeAwsApi"
        inputs = {
          Service     = "EC2"
          Api         = "StartInstances"
          InstanceIds = ["{{ InstanceId }}"]
        }
      }
    ]
  })
}

# Runbook: Create Snapshot Before Action
resource "aws_ssm_document" "create_snapshot" {
  name          = "CreateSnapshotBeforeAction"
  document_type = "Automation"
  content = jsonencode({
    schemaVersion = "0.3"
    description   = "Create EBS snapshot before remediation"
    assumeRole    = "{{ AutomationAssumeRole }}"
    parameters = {
      InstanceId = {
        type        = "String"
        description = "EC2 Instance ID"
      }
      AutomationAssumeRole = {
        type    = "String"
        default = aws_iam_role.automation_ec2.arn
      }
    }
    mainSteps = [
      {
        name   = "GetVolumeId"
        action = "aws:executeAwsApi"
        inputs = {
          Service     = "EC2"
          Api         = "DescribeInstances"
          InstanceIds = ["{{ InstanceId }}"]
        }
        outputs = [{
          Name     = "VolumeId"
          Selector = "$.Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId"
          Type     = "String"
        }]
      },
      {
        name   = "CreateSnapshot"
        action = "aws:executeAwsApi"
        inputs = {
          Service     = "EC2"
          Api         = "CreateSnapshot"
          VolumeId    = "{{ GetVolumeId.VolumeId }}"
          Description = "Pre-remediation snapshot for {{ InstanceId }}"
        }
      }
    ]
  })
}

# EventBridge Role
resource "aws_iam_role" "eventbridge" {
  name = "eventbridge-start-automation"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge" {
  role = aws_iam_role.eventbridge.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:StartAutomationExecution"]
      Resource = [
        "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:automation-definition/${aws_ssm_document.restart_ecs.name}:*",
        "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:automation-definition/${aws_ssm_document.recover_ec2.name}:*"
      ]
    },
    {
      Effect   = "Allow"
      Action   = ["iam:PassRole"]
      Resource = [aws_iam_role.automation_ecs.arn, aws_iam_role.automation_ec2.arn]
    }]
  })
}

# EventBridge Rule: Alarm to Restart ECS
resource "aws_cloudwatch_event_rule" "alarm_to_restart_ecs" {
  name        = "AlarmToRestartEcs"
  description = "When specific alarm triggers, restart ECS service"
  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      state      = { value = ["ALARM"] }
      alarmName  = [{ prefix = "ECS-" }]
    }
  })
}

resource "aws_cloudwatch_event_target" "restart_ecs" {
  rule     = aws_cloudwatch_event_rule.alarm_to_restart_ecs.name
  arn      = "arn:aws:ssm:${var.region}::automation-definition/${aws_ssm_document.restart_ecs.name}"
  role_arn = aws_iam_role.eventbridge.arn

  input_transformer {
    input_paths = {
      alarmName = "$.detail.alarmName"
    }
    input_template = jsonencode({
      Cluster              = var.ecs_cluster
      Service              = var.ecs_service
      AutomationAssumeRole = aws_iam_role.automation_ecs.arn
    })
  }
}

# Parameter Store for runbook configuration
resource "aws_ssm_parameter" "ecs_cluster" {
  name  = "/incident-response/ecs/cluster"
  type  = "String"
  value = var.ecs_cluster
}

resource "aws_ssm_parameter" "ecs_service" {
  name  = "/incident-response/ecs/service"
  type  = "String"
  value = var.ecs_service
}

# OpsCenter OpsItem creation from alarms
resource "aws_cloudwatch_event_rule" "alarm_to_opsitem" {
  name        = "AlarmToOpsItem"
  description = "Create OpsItem for non-critical alarms"
  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      state     = { value = ["ALARM"] }
      alarmName = [{ prefix = "Warning-" }]
    }
  })
}

resource "aws_cloudwatch_event_target" "opsitem" {
  rule = aws_cloudwatch_event_rule.alarm_to_opsitem.name
  arn  = "arn:aws:ssm:${var.region}::opsitem"

  input_transformer {
    input_paths = {
      alarmName   = "$.detail.alarmName"
      alarmReason = "$.detail.state.reason"
      timestamp   = "$.detail.state.timestamp"
    }
    input_template = <<-EOF
      {
        "title": "CloudWatch Alarm: <alarmName>",
        "description": "Alarm triggered at <timestamp>. Reason: <alarmReason>",
        "source": "CloudWatch",
        "severity": "3"
      }
    EOF
  }
}

# Outputs
output "restart_ecs_document" {
  value = aws_ssm_document.restart_ecs.name
}

output "recover_ec2_document" {
  value = aws_ssm_document.recover_ec2.name
}

output "eventbridge_rule" {
  value = aws_cloudwatch_event_rule.alarm_to_restart_ecs.name
}

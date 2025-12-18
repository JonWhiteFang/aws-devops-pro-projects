variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "distribution_regions" {
  type    = list(string)
  default = ["eu-west-1", "eu-west-2"]
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# IAM role for Image Builder
resource "aws_iam_role" "image_builder" {
  name = "EC2ImageBuilderRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "image_builder_ssm" {
  role       = aws_iam_role.image_builder.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "image_builder_ec2" {
  role       = aws_iam_role.image_builder.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

resource "aws_iam_instance_profile" "image_builder" {
  name = "EC2ImageBuilderProfile"
  role = aws_iam_role.image_builder.name
}

# Image Builder Component - Security hardening
resource "aws_imagebuilder_component" "security_hardening" {
  name        = "security-hardening"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Security hardening for Amazon Linux 2023"

  data = yamlencode({
    schemaVersion = 1.0
    phases = [{
      name = "build"
      steps = [
        {
          name   = "DisableRootLogin"
          action = "ExecuteBash"
          inputs = { commands = ["sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config"] }
        },
        {
          name   = "EnableIMDSv2"
          action = "ExecuteBash"
          inputs = { commands = ["echo 'HttpPutResponseHopLimit: 1' >> /etc/cloud/cloud.cfg.d/99-imdsv2.cfg"] }
        },
        {
          name   = "UpdatePackages"
          action = "ExecuteBash"
          inputs = { commands = ["yum update -y"] }
        },
        {
          name   = "InstallCloudWatchAgent"
          action = "ExecuteBash"
          inputs = { commands = ["yum install -y amazon-cloudwatch-agent"] }
        }
      ]
    }]
  })
}

# Image Builder Component - Test
resource "aws_imagebuilder_component" "test" {
  name        = "ami-test"
  platform    = "Linux"
  version     = "1.0.0"
  description = "Test AMI configuration"

  data = yamlencode({
    schemaVersion = 1.0
    phases = [{
      name = "test"
      steps = [
        {
          name   = "TestSSHConfig"
          action = "ExecuteBash"
          inputs = { commands = ["grep 'PermitRootLogin no' /etc/ssh/sshd_config"] }
        },
        {
          name   = "TestCloudWatchAgent"
          action = "ExecuteBash"
          inputs = { commands = ["rpm -q amazon-cloudwatch-agent"] }
        }
      ]
    }]
  })
}

# Image Recipe
resource "aws_imagebuilder_image_recipe" "main" {
  name         = "hardened-al2023"
  parent_image = "arn:aws:imagebuilder:${var.region}:aws:image/amazon-linux-2023-x86/x.x.x"
  version      = "1.0.0"

  component {
    component_arn = aws_imagebuilder_component.security_hardening.arn
  }

  component {
    component_arn = "arn:aws:imagebuilder:${var.region}:aws:component/amazon-cloudwatch-agent-linux/x.x.x"
  }

  block_device_mapping {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }
}

# Infrastructure Configuration
resource "aws_imagebuilder_infrastructure_configuration" "main" {
  name                          = "hardened-ami-infra"
  instance_profile_name         = aws_iam_instance_profile.image_builder.name
  instance_types                = ["t3.medium"]
  terminate_instance_on_failure = true

  logging {
    s3_logs {
      s3_bucket_name = aws_s3_bucket.logs.id
      s3_key_prefix  = "image-builder"
    }
  }
}

resource "aws_s3_bucket" "logs" {
  bucket        = "image-builder-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

# Distribution Configuration
resource "aws_imagebuilder_distribution_configuration" "main" {
  name = "hardened-ami-distribution"

  dynamic "distribution" {
    for_each = var.distribution_regions
    content {
      region = distribution.value
      ami_distribution_configuration {
        name               = "hardened-al2023-{{ imagebuilder:buildDate }}"
        description        = "Hardened Amazon Linux 2023 AMI"
        ami_tags           = { Name = "hardened-al2023" }
        target_account_ids = [data.aws_caller_identity.current.account_id]
      }
    }
  }
}

# Image Pipeline
resource "aws_imagebuilder_image_pipeline" "main" {
  name                             = "hardened-ami-pipeline"
  image_recipe_arn                 = aws_imagebuilder_image_recipe.main.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.main.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.main.arn

  schedule {
    schedule_expression                = "cron(0 0 ? * SUN *)" # Weekly on Sunday
    pipeline_execution_start_condition = "EXPRESSION_MATCH_ONLY"
  }

  image_tests_configuration {
    image_tests_enabled = true
    timeout_minutes     = 60
  }
}

output "pipeline_arn" {
  value = aws_imagebuilder_image_pipeline.main.arn
}

output "recipe_arn" {
  value = aws_imagebuilder_image_recipe.main.arn
}

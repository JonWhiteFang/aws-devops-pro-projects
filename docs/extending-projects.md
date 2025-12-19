# Extending Projects for Real-World Use

How to customize and extend these learning projects for production environments.

## General Extension Patterns

### Adding Environments (Dev/Staging/Prod)

Use Terraform workspaces or separate tfvars files:

```bash
# Option 1: Workspaces
terraform workspace new dev
terraform workspace new prod
terraform apply -var-file=environments/dev.tfvars

# Option 2: Separate directories
environments/
├── dev/
│   ├── main.tf -> ../../modules/
│   └── terraform.tfvars
├── staging/
└── prod/
```

### Modularizing Code

Convert projects to reusable modules:

```hcl
# modules/ecs-service/main.tf
variable "cluster_name" {}
variable "service_name" {}
variable "container_image" {}

resource "aws_ecs_service" "main" {
  name            = var.service_name
  cluster         = var.cluster_name
  # ...
}

# Usage
module "api_service" {
  source          = "./modules/ecs-service"
  cluster_name    = "production"
  service_name    = "api"
  container_image = "123456789.dkr.ecr.eu-west-1.amazonaws.com/api:latest"
}
```

### Adding Tagging Strategy

Implement consistent tagging across all resources:

```hcl
# variables.tf
variable "common_tags" {
  type = map(string)
  default = {
    Project     = "my-app"
    Environment = "dev"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}

# Use in resources
resource "aws_instance" "example" {
  tags = merge(var.common_tags, {
    Name = "my-instance"
  })
}
```

---

## Project A: CI/CD Extensions

### Add Multiple Environments

```hcl
# Deploy to dev, then staging, then prod
resource "aws_codepipeline" "main" {
  stage {
    name = "Deploy-Dev"
    action {
      name     = "Deploy"
      provider = "ECS"
      configuration = {
        ClusterName = aws_ecs_cluster.dev.name
        ServiceName = aws_ecs_service.dev.name
      }
    }
  }
  
  stage {
    name = "Approve-Staging"
    action {
      name     = "Approval"
      provider = "Manual"
    }
  }
  
  stage {
    name = "Deploy-Staging"
    # ...
  }
  
  stage {
    name = "Approve-Prod"
    action {
      name     = "Approval"
      provider = "Manual"
    }
  }
  
  stage {
    name = "Deploy-Prod"
    # ...
  }
}
```

### Add GitHub as Source

Replace CodeCommit with GitHub:

```hcl
resource "aws_codepipeline" "main" {
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        Owner      = "your-org"
        Repo       = "your-repo"
        Branch     = "main"
        OAuthToken = data.aws_secretsmanager_secret_version.github_token.secret_string
      }
    }
  }
}
```

### Add Container Security Scanning

```hcl
# Add Trivy scanning in CodeBuild
resource "aws_codebuild_project" "security_scan" {
  name = "container-security-scan"
  
  environment {
    image = "aquasec/trivy:latest"
  }
  
  # buildspec includes:
  # trivy image --exit-code 1 --severity HIGH,CRITICAL $IMAGE_URI
}
```

---

## Project B: Config Extensions

### Add Custom Rules for Your Organization

```hcl
# Example: Require specific tags
resource "aws_config_config_rule" "required_cost_tags" {
  name = "required-cost-allocation-tags"
  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.cost_tags.arn
  }
  input_parameters = jsonencode({
    requiredTags = ["CostCenter", "Project", "Owner", "Environment"]
  })
}

# Example: Check for approved AMIs only
resource "aws_config_config_rule" "approved_amis" {
  name = "approved-amis-only"
  source {
    owner             = "AWS"
    source_identifier = "APPROVED_AMIS_BY_ID"
  }
  input_parameters = jsonencode({
    amiIds = "ami-xxx,ami-yyy,ami-zzz"
  })
}
```

### Add Conformance Packs

```hcl
resource "aws_config_conformance_pack" "security_baseline" {
  name = "security-baseline"
  
  template_body = <<EOF
Resources:
  S3BucketPublicReadProhibited:
    Type: AWS::Config::ConfigRule
    Properties:
      ConfigRuleName: s3-bucket-public-read-prohibited
      Source:
        Owner: AWS
        SourceIdentifier: S3_BUCKET_PUBLIC_READ_PROHIBITED
  # Add more rules...
EOF
}
```

---

## Project C: Multi-Region Extensions

### Add Active-Active Architecture

```hcl
# Instead of failover, use weighted routing
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.example.com"
  type    = "A"
  
  set_identifier = "region-a"
  weighted_routing_policy {
    weight = 50
  }
  
  alias {
    name                   = aws_lb.region_a.dns_name
    zone_id                = aws_lb.region_a.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "api_b" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.example.com"
  type    = "A"
  
  set_identifier = "region-b"
  weighted_routing_policy {
    weight = 50
  }
  
  alias {
    name                   = aws_lb.region_b.dns_name
    zone_id                = aws_lb.region_b.zone_id
    evaluate_target_health = true
  }
}
```

### Add Global Accelerator

```hcl
resource "aws_globalaccelerator_accelerator" "main" {
  name            = "global-api"
  ip_address_type = "IPV4"
  enabled         = true
}

resource "aws_globalaccelerator_listener" "main" {
  accelerator_arn = aws_globalaccelerator_accelerator.main.id
  protocol        = "TCP"
  port_range {
    from_port = 443
    to_port   = 443
  }
}

resource "aws_globalaccelerator_endpoint_group" "region_a" {
  listener_arn = aws_globalaccelerator_listener.main.id
  endpoint_group_region = "eu-west-1"
  
  endpoint_configuration {
    endpoint_id = aws_lb.region_a.arn
    weight      = 100
  }
}
```

---

## Project D: Observability Extensions

### Add Application Performance Monitoring

```hcl
# CloudWatch Application Insights
resource "aws_applicationinsights_application" "main" {
  resource_group_name = aws_resourcegroups_group.app.name
  auto_config_enabled = true
}

# Container Insights with enhanced observability
resource "aws_ecs_cluster" "main" {
  setting {
    name  = "containerInsights"
    value = "enhanced"
  }
}
```

### Add Cross-Account Dashboard

```hcl
# Share dashboard across accounts
resource "aws_cloudwatch_dashboard" "cross_account" {
  dashboard_name = "cross-account-overview"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", "prod", { accountId = "111111111111" }],
            ["AWS/ECS", "CPUUtilization", "ClusterName", "prod", { accountId = "222222222222" }]
          ]
        }
      }
    ]
  })
}
```

---

## Project E: Incident Response Extensions

### Add PagerDuty Integration

```hcl
# SNS to PagerDuty
resource "aws_sns_topic_subscription" "pagerduty" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "https"
  endpoint  = "https://events.pagerduty.com/integration/YOUR_KEY/enqueue"
}
```

### Add Slack Notifications

```hcl
# Lambda for Slack formatting
resource "aws_lambda_function" "slack_notifier" {
  function_name = "slack-alert-notifier"
  handler       = "index.handler"
  runtime       = "python3.11"
  
  environment {
    variables = {
      SLACK_WEBHOOK_URL = data.aws_secretsmanager_secret_version.slack.secret_string
    }
  }
}

resource "aws_sns_topic_subscription" "slack" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier.arn
}
```

---

## Project F: Governance Extensions

### Add AWS Control Tower Integration

```hcl
# Register accounts with Control Tower
resource "aws_controltower_control" "require_imdsv2" {
  control_identifier = "arn:aws:controltower:eu-west-1::control/AWS-GR_EC2_INSTANCE_NO_PUBLIC_IP"
  target_identifier  = "arn:aws:organizations::ACCOUNT:ou/o-xxx/ou-xxx"
}
```

### Add Automated Account Provisioning

```hcl
# Account Factory
resource "aws_organizations_account" "workload" {
  name      = "workload-${var.environment}"
  email     = "aws+workload-${var.environment}@example.com"
  role_name = "OrganizationAccountAccessRole"
  
  lifecycle {
    ignore_changes = [role_name]
  }
}

# Apply baseline via StackSet
resource "aws_cloudformation_stack_set_instance" "baseline" {
  stack_set_name = aws_cloudformation_stack_set.baseline.name
  account_id     = aws_organizations_account.workload.id
  region         = "eu-west-1"
}
```

---

## Project G: Additional Extensions

### Image Builder with Inspector Integration

```hcl
resource "aws_imagebuilder_image_pipeline" "main" {
  image_scanning_configuration {
    image_scanning_enabled = true
    ecr_configuration {
      repository_name = aws_ecr_repository.golden_ami.name
    }
  }
}
```

### Service Catalog with Budgets

```hcl
resource "aws_servicecatalog_budget_resource_association" "limit" {
  budget_name = aws_budgets_budget.product_limit.name
  resource_id = aws_servicecatalog_product.s3_bucket.id
}

resource "aws_budgets_budget" "product_limit" {
  name         = "service-catalog-limit"
  budget_type  = "COST"
  limit_amount = "100"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
}
```

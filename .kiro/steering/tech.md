---
inclusion: fileMatch
fileMatchPattern: ['**/*.tf', '**/*.tfvars', '**/template.yaml', '**/*.py']
---

# Technology Stack

## Version Requirements

- Terraform >= 1.5.0
- AWS Provider ~> 5.0
- Python 3.11 (Lambda functions)
- SAM CLI (project-g Lambda deployments only)

## Terraform Code Style

When writing or modifying Terraform:
- Use `jsonencode()` for inline IAM policies, or `data.aws_iam_policy_document` for complex policies
- Default region: `eu-west-1` (always use `var.region` for configurability)
- Resource naming: `${var.project}-<type>` (e.g., `demo-ecs-bluegreen-alb`)
- IAM role naming: `${var.project}-<purpose>` (e.g., `demo-ecs-bluegreen-task-exec`)
- Variables: snake_case with descriptions and sensible defaults
- Outputs: snake_case, documented, expose ARNs/URLs/connection info
- Lambda code: co-locate `.py` files in `infra-terraform/`, use `archive_file` data source for zipping

## Backend Configuration

All projects use S3 backend with native locking:
```hcl
terraform {
  backend "s3" {
    use_lockfile = true
    # Each project has unique key
  }
}
```

## Quality Gates

Code must pass before merge:
1. `terraform fmt` - canonical formatting
2. `terraform validate` - syntax validation
3. `tflint` - AWS ruleset linting
4. `checkov` - security scanning (no high/critical findings)

Run locally: `pre-commit run --all-files`

## AWS Services Reference

| Category | Services |
|----------|----------|
| Compute/Deploy | ECS Fargate, ECR, CodePipeline, CodeBuild, CodeDeploy |
| Config/Compliance | AWS Config, Lambda, SSM Automation |
| HA/DR | Route 53, DynamoDB Global Tables, AWS Backup |
| Observability | CloudWatch (Dashboards, Alarms, Logs, Synthetics), X-Ray |
| Events | EventBridge, OpsCenter, Parameter Store |
| Governance | Organizations, CloudTrail, Security Hub, GuardDuty, IAM Access Analyzer |
| Provisioning | EC2 Image Builder, Service Catalog |

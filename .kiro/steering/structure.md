---
inclusion: always
---

# Project Structure

## Repository Layout

```
project-a-cicd-ecs-bluegreen/           # CI/CD with ECS blue/green
project-b-iac-config-remediation/       # AWS Config + auto-remediation
project-c-multiregion-route53-dynamodb/ # Multi-region HA
project-d-observability-cloudwatch/     # CloudWatch, Synthetics, X-Ray
project-e-incident-response-ssm/        # SSM Automation runbooks
project-f-governance-multiaccount/      # SCPs, Security Hub, GuardDuty
project-g-additional-topics/            # Image Builder, SAM, Service Catalog
docs/guides/                            # Step-by-step deployment guides
.github/workflows/                      # CI validation
```

## Standard Project Structure

All projects follow this pattern:

```
project-X/
├── README.md                    # Prerequisites, deployment, cleanup, costs
├── infra-terraform/
│   ├── backend.tf               # S3 backend with use_lockfile = true
│   ├── providers.tf             # AWS provider ~> 5.0
│   ├── variables.tf             # Inputs with descriptions + defaults
│   ├── outputs.tf               # ARNs, URLs, connection info
│   ├── terraform.tfvars.example # Copy to terraform.tfvars before apply
│   └── <resource>.tf            # One file per logical grouping
└── app/ or src/                 # Application code (if applicable)
```

## Naming Conventions

| Element | Pattern | Example |
|---------|---------|---------|
| Resources | `${var.project}-<type>` | `demo-ecs-bluegreen-alb` |
| IAM Roles | `${var.project}-<purpose>` | `demo-ecs-bluegreen-task-exec` |
| Variables | snake_case + description | `container_port` |
| Outputs | snake_case + documented | `alb_dns_name` |

## Code Organization Rules

- One logical grouping per `.tf` file (e.g., `ecs.tf`, `network.tf`, `codepipeline.tf`)
- IAM policies: use `jsonencode()` inline or `data.aws_iam_policy_document`
- Lambda code: co-locate `.py` files in `infra-terraform/`, zip via `archive_file` data source
- Default region: `eu-west-1` (configurable via `var.region`)

## When Creating/Modifying Files

- Place Terraform files in `infra-terraform/` subdirectory
- Always include `backend.tf` with S3 backend configuration
- Provide `terraform.tfvars.example` with sample values
- Document outputs for cross-project references
- Keep README.md updated with deployment steps and cost estimates

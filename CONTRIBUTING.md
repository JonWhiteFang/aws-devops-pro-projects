# Contributing

Thanks for your interest in contributing to AWS DevOps Pro Projects.

## Development Setup

1. Fork and clone the repository
2. Install pre-commit hooks:

```bash
pip install pre-commit
pre-commit install
```

3. Configure your backend:

```bash
cp backend.hcl.example backend.hcl
# Edit with your S3 bucket
```

## Code Standards

All Terraform code must pass:

- `terraform fmt` — canonical formatting
- `terraform validate` — syntax validation
- `tflint` — AWS ruleset linting
- `checkov` — security scanning (no high/critical findings)

Run locally before committing:

```bash
pre-commit run --all-files
```

## Project Structure

Each project follows this pattern:

```
project-X/
├── README.md                    # Prerequisites, deployment, cleanup, costs
├── infra-terraform/
│   ├── backend.tf               # S3 backend (key only)
│   ├── providers.tf             # AWS provider ~> 5.0, required_version >= 1.5.0
│   ├── variables.tf             # Inputs with descriptions + defaults
│   ├── outputs.tf               # ARNs, URLs, connection info
│   ├── terraform.tfvars.example # Sample values
│   └── <resource>.tf            # One file per logical grouping
```

## Naming Conventions

| Element | Pattern | Example |
|---------|---------|---------|
| Resources | `${var.project}-<type>` | `demo-ecs-bluegreen-alb` |
| IAM Roles | `${var.project}-<purpose>` | `demo-ecs-bluegreen-task-exec` |
| Variables | snake_case + description | `container_port` |
| Outputs | snake_case + documented | `alb_dns_name` |

## Pull Request Process

1. Create a feature branch from `main`
2. Make your changes following the code standards
3. Ensure all pre-commit hooks pass
4. Update relevant documentation (README, overview.md)
5. Submit a pull request with a clear description

## Exam Alignment

When adding or modifying code, consider which AWS DevOps Professional exam domain it covers:

| Domain | Weight | Focus |
|--------|--------|-------|
| 1: SDLC Automation | 22% | CI/CD, deployments, rollback |
| 2: Configuration Management & IaC | 17% | Config, compliance, IaC |
| 3: Monitoring & Logging | 15% | CloudWatch, X-Ray, logs |
| 4: Incident & Event Response | 15% | SSM, EventBridge, automation |
| 5: HA, Fault Tolerance, DR | 18% | Multi-region, failover, backup |
| 6: Policies & Standards | 13% | SCPs, governance, security |

## Questions?

Open an issue for questions or suggestions.

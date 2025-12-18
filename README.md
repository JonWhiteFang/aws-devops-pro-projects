# AWS DevOps Pro — Practical Projects

Ready-to-adapt infrastructure code for seven hands-on projects aligned to the AWS Certified DevOps Engineer – Professional exam.

## Projects

| Project | Domain | Description |
|---------|--------|-------------|
| [A: CI/CD ECS Blue/Green](project-a-cicd-ecs-bluegreen/) | SDLC Automation | CodePipeline, CodeBuild, CodeDeploy with ECS Fargate |
| [B: Config Remediation](project-b-iac-config-remediation/) | Configuration Management | AWS Config rules with SSM auto-remediation |
| [C: Multi-Region](project-c-multiregion-route53-dynamodb/) | High Availability & DR | Route 53 failover, DynamoDB Global Tables, AWS Backup |
| [D: Observability](project-d-observability-cloudwatch/) | Monitoring & Logging | CloudWatch dashboards, alarms, X-Ray, Synthetics |
| [E: Incident Response](project-e-incident-response-ssm/) | Incident Response | SSM Automation runbooks, EventBridge, OpsCenter |
| [F: Governance](project-f-governance-multiaccount/) | Policies & Standards | SCPs, CloudTrail, Security Hub, GuardDuty, StackSets |
| [G: Additional Topics](project-g-additional-topics/) | Mixed | EC2 Image Builder, Lambda SAM, Service Catalog |

## Quick Start

```bash
cd project-a-cicd-ecs-bluegreen/infra-terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- Appropriate IAM permissions per project

## Repository Structure

```
├── project-a-cicd-ecs-bluegreen/
├── project-b-iac-config-remediation/
├── project-c-multiregion-route53-dynamodb/
├── project-d-observability-cloudwatch/
├── project-e-incident-response-ssm/
├── project-f-governance-multiaccount/
├── project-g-additional-topics/
├── docs/
│   ├── architecture-diagrams.md    # Mermaid diagrams
│   └── exam-question-mapping.md    # Exam topic → project mapping
├── .github/workflows/              # CI/CD validation
├── .pre-commit-config.yaml         # Pre-commit hooks
├── overview.md                     # Detailed project overview
└── suggestions.md                  # Implementation status
```

## Documentation

- [overview.md](overview.md) - Detailed project breakdown
- [docs/architecture-diagrams.md](docs/architecture-diagrams.md) - Visual architecture diagrams
- [docs/exam-question-mapping.md](docs/exam-question-mapping.md) - Exam topics mapped to projects
- Per-project READMEs with deployment instructions

## Validation

Pre-commit hooks and GitHub Actions validate:
- Terraform formatting (`terraform fmt`)
- Terraform validation (`terraform validate`)
- Security scanning (Checkov)
- Linting (TFLint)

```bash
# Install pre-commit
pip install pre-commit
pre-commit install

# Run manually
pre-commit run --all-files
```

## Exam Domain Mapping

| Domain | Weight | Projects |
|--------|--------|----------|
| 1: SDLC Automation | 22% | A, G |
| 2: Configuration Management & IaC | 17% | B, F, G |
| 3: Monitoring & Logging | 15% | D |
| 4: Incident & Event Response | 15% | E |
| 5: High Availability, Fault Tolerance, DR | 18% | C |
| 6: Policies & Standards Automation | 13% | F |

## Estimated Costs

Running all projects simultaneously: ~$100-150/month

Individual projects range from <$5 to ~$50/month depending on usage.

## Cleanup

Each project includes cleanup instructions:

```bash
cd project-X/infra-terraform
terraform destroy
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Ensure pre-commit hooks pass
4. Submit a pull request

## License

MIT

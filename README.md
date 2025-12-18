# AWS DevOps Pro — Practical Projects

Ready-to-adapt infrastructure code for seven hands-on projects aligned to the AWS Certified DevOps Engineer – Professional exam.

## Projects

### [A: CI/CD ECS Blue/Green](project-a-cicd-ecs-bluegreen/)
Complete CI/CD pipeline demonstrating blue/green deployments to ECS Fargate. CodePipeline orchestrates the workflow: CodeCommit triggers builds, CodeBuild creates Docker images and pushes to ECR, and CodeDeploy manages traffic shifting between blue and green target groups. The ECS service runs behind an Application Load Balancer with two target groups for zero-downtime deployments. Automatic rollback is configured to trigger when CloudWatch alarms detect elevated error rates or latency. Covers buildspec.yml configuration, appspec.yaml for ECS deployments, task definition templating, and IAM roles for cross-service permissions.

### [B: Config Remediation](project-b-iac-config-remediation/)
AWS Config deployment with both managed and custom rules, plus automatic remediation via SSM Automation. Managed rules check for S3 public access, unencrypted EBS volumes, and unencrypted RDS storage. A custom Lambda-backed rule evaluates EC2 instances for required tags (Owner and Environment). When instances are found non-compliant, an SSM Automation document automatically applies default tags. Demonstrates the Config recorder setup, delivery channel to S3, rule evaluation modes, and the remediation configuration that links Config rules to SSM documents. Useful for understanding compliance-as-code patterns.

### [C: Multi-Region](project-c-multiregion-route53-dynamodb/)
Multi-region active-passive architecture using Route 53 for DNS-based failover. Deploys identical Lambda functions behind ALBs in two regions (eu-west-1 and eu-west-2). Route 53 health checks monitor each region's ALB endpoint, automatically routing traffic to the secondary region when the primary fails. Also demonstrates latency-based routing as an alternative pattern. DynamoDB Global Tables provide multi-region data replication with eventual consistency. AWS Backup creates cross-region backup copies for disaster recovery. Route 53 configuration is optional (requires a hosted zone) - the core infrastructure deploys without it.

### [D: Observability](project-d-observability-cloudwatch/)
Comprehensive CloudWatch observability stack covering dashboards, alarms, logs, and synthetic monitoring. The dashboard displays ALB metrics (5xx errors, request count, latency) and ECS metrics (CPU, memory utilisation). Three alarm types are demonstrated: threshold-based (5xx count > 5), composite (triggers when multiple conditions are met simultaneously), and anomaly detection (alerts on unusual request patterns). Log metric filters extract error counts and latency values from application logs, publishing them as custom metrics. X-Ray sampling rules and trace groups enable distributed tracing. A CloudWatch Synthetics canary performs scheduled endpoint monitoring. Custom metrics via Embedded Metric Format (EMF) show how applications can publish high-cardinality metrics efficiently.

### [E: Incident Response](project-e-incident-response-ssm/)
Automated incident response framework using SSM Automation runbooks triggered by EventBridge rules. Three runbooks are provided: RestartEcsService (forces new deployment to replace unhealthy tasks), RecoverEC2Instance (stop/start cycle for instance recovery), and CreateSnapshotBeforeAction (creates EBS snapshot before remediation). EventBridge rules match CloudWatch alarm state changes and invoke the appropriate runbook automatically. Parameter Store holds configuration values for the runbooks. OpsCenter integration creates OpsItems for non-critical alarms, providing a queue for manual review. Demonstrates the pattern of alarm → event → automation that reduces mean time to recovery without human intervention.

### [F: Governance & Security](project-f-governance-multiaccount/)
Account-level security services deployment for governance and threat detection. CloudTrail creates a multi-region trail with log file validation, storing events in S3 for audit purposes. Security Hub aggregates security findings from multiple sources and evaluates against compliance standards (CIS, AWS Foundational Security Best Practices). GuardDuty provides continuous threat detection by analysing VPC flow logs, CloudTrail events, and DNS logs. IAM Access Analyzer identifies resources shared with external entities, helping detect unintended public or cross-account access. Example SCP policy files are included for exam study - these demonstrate region restriction, IMDSv2 enforcement, and root user denial patterns, but require AWS Organizations to deploy.

### [G: Additional Topics](project-g-additional-topics/)
Supplementary projects covering exam topics not addressed in the main projects. EC2 Image Builder creates automated AMI pipelines with build and test phases, including scheduled builds and distribution to multiple regions. Lambda SAM deployment demonstrates serverless CI/CD with CodeDeploy hooks for pre/post traffic shifting validation, gradual deployment preferences (canary, linear), and automatic rollback on errors. Service Catalog provides a portfolio with an S3 bucket product, launch constraints for controlled provisioning, and TagOptions for consistent resource tagging. These smaller projects can be deployed independently to explore specific exam topics.

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

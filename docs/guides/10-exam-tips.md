# Cost Management & Exam Preparation

Tips for managing costs and preparing for the AWS DevOps Professional exam.

---

## Cost Management

### Monitoring Costs

```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE | jq '.ResultsByTime[0].Groups[] | {service: .Keys[0], cost: .Metrics.BlendedCost.Amount}'
```

### Cost-Saving Tips

1. **Destroy resources when not in use** — Don't leave projects running overnight
2. **Use t3.micro/small instances** — Sufficient for learning
3. **Minimise NAT Gateways** — Use one per VPC, not per AZ
4. **Delete unused EBS volumes** — Check for orphaned volumes
5. **Empty S3 buckets before deletion** — Avoid storage charges
6. **Use Spot instances for Image Builder** — Significant savings

### Setting Up Budget Alerts

```bash
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget '{
    "BudgetName": "DevOpsPro-Daily",
    "BudgetLimit": {"Amount": "20", "Unit": "USD"},
    "TimeUnit": "DAILY",
    "BudgetType": "COST"
  }' \
  --notifications-with-subscribers '[{
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80,
      "ThresholdType": "PERCENTAGE"
    },
    "Subscribers": [{
      "SubscriptionType": "EMAIL",
      "Address": "your-email@example.com"
    }]
  }]'
```

---

## Exam Preparation

### Using These Projects

1. **Deploy each project at least once** — Hands-on experience is invaluable
2. **Break things intentionally** — Test rollbacks, failovers, and recovery
3. **Read the Terraform code** — Understand every resource and its purpose
4. **Correlate with exam domains** — Use `docs/exam-question-mapping.md`
5. **Time yourself** — Practice deploying under time pressure

### Key Concepts by Domain

| Domain | Key Concepts | Project |
|--------|--------------|---------|
| 1 | Pipeline stages, deployment strategies, rollback | A |
| 2 | Config rules, remediation, IaC best practices | B |
| 3 | Metrics, alarms, logs, tracing | D |
| 4 | Event-driven automation, runbooks | E |
| 5 | Multi-region, failover, DR | C |
| 6 | SCPs, governance, StackSets | F |

### Recommended Study Order

- **Week 1:** Projects A and B (CI/CD and Config)
- **Week 2:** Projects C and D (Multi-region and Observability)
- **Week 3:** Projects E and F (Incident Response and Governance)
- **Week 4:** Project G and review all projects

### Additional Resources

- [AWS DevOps Professional Exam Guide](https://aws.amazon.com/certification/certified-devops-engineer-professional/)
- [AWS Whitepapers](https://aws.amazon.com/whitepapers/)
  - DevOps and AWS
  - Practicing Continuous Integration and Continuous Delivery on AWS
  - Infrastructure as Code
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

### Practice Questions Focus Areas

Based on these projects, focus on:

- CodePipeline action types and stage ordering
- CodeDeploy deployment configurations (blue/green vs in-place)
- Config rule evaluation and remediation
- CloudWatch alarm types and actions
- SSM Automation document structure
- Route 53 routing policies and health checks
- DynamoDB Global Tables consistency
- SCP evaluation logic
- StackSets deployment options
- Image Builder pipeline components

---

## Quick Reference

### Useful AWS CLI Commands

```bash
# Get current identity
aws sts get-caller-identity

# List all regions
aws ec2 describe-regions --query 'Regions[*].RegionName' --output table

# Get latest Amazon Linux 2023 AMI
aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 --query 'Parameter.Value' --output text

# Check service quotas
aws service-quotas list-service-quotas --service-code <service>

# Get resource tags
aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=devops-pro
```

### Terraform Commands

```bash
terraform fmt -recursive      # Format code
terraform validate            # Validate configuration
terraform show                # Show current state
terraform state list          # List resources in state
terraform import <type>.<name> <id>  # Import existing resource
terraform state rm <resource> # Remove from state (no destroy)
terraform refresh             # Refresh state
terraform apply -target=<resource>   # Target specific resource
terraform destroy -target=<resource> # Destroy specific resource
```

---

## Project Directory Structure

```
aws-devops-pro-projects/
├── README.md
├── overview.md
├── suggestions.md
├── .pre-commit-config.yaml
├── .tflint.hcl
├── .github/workflows/validate.yml
├── docs/
│   ├── architecture-diagrams.md
│   ├── exam-question-mapping.md
│   └── guides/
│       ├── README.md
│       ├── 00-prerequisites.md
│       ├── 01-project-a-cicd-ecs.md
│       ├── 02-project-b-config-remediation.md
│       ├── 03-project-c-multiregion.md
│       ├── 04-project-d-observability.md
│       ├── 05-project-e-incident-response.md
│       ├── 06-project-f-governance.md
│       ├── 07-project-g-additional.md
│       ├── 08-teardown.md
│       ├── 09-troubleshooting.md
│       └── 10-exam-tips.md
├── project-a-cicd-ecs-bluegreen/
├── project-b-iac-config-remediation/
├── project-c-multiregion-route53-dynamodb/
├── project-d-observability-cloudwatch/
├── project-e-incident-response-ssm/
├── project-f-governance-multiaccount/
└── project-g-additional-topics/
```

---

**Good luck with your AWS DevOps Professional exam!**

# Project F: Governance & Security Services

Deploys account-level security and governance services: CloudTrail, Security Hub, GuardDuty, and IAM Access Analyzer.

## Architecture

```
AWS Account
    ↓
┌───────────────────────────────────┐
│  CloudTrail → S3 Bucket           │
│  Security Hub (findings)          │
│  GuardDuty (threat detection)     │
│  IAM Access Analyzer (external    │
│    access findings)               │
└───────────────────────────────────┘
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- Permissions: CloudTrail, Security Hub, GuardDuty, IAM, S3

### Dependencies

**Required:**
- S3 state bucket (`devops-pro-tfstate-<account-id>`) from bootstrap setup

## Deployment

```bash
cd infra-terraform
terraform init
terraform plan
terraform apply
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| region | AWS region | eu-west-1 |

## Security Services Deployed

| Service | Description |
|---------|-------------|
| CloudTrail | Multi-region trail with log file validation |
| Security Hub | Aggregated security findings |
| GuardDuty | Threat detection |
| IAM Access Analyzer | Detects external access to resources |

## SCP Reference (AWS Organizations only)

The `policies/` directory contains example SCPs for exam study:

| Policy | Description |
|--------|-------------|
| scp-deny-public-s3.json | Blocks public S3 bucket ACLs |
| scp-deny-unsupported-regions.json | Restricts actions to allowed regions |
| scp-require-imdsv2.json | Requires IMDSv2 for EC2 instances |
| scp-deny-root-user.json | Blocks root user actions (except billing) |

**Note:** SCPs require AWS Organizations and cannot be deployed in a standalone account.

## Cleanup

```bash
terraform destroy
```

## Estimated Costs

- CloudTrail: $2/100,000 events
- Security Hub: $0.0010/finding-ingestion
- GuardDuty: Based on data analysed
- S3: Storage for CloudTrail logs

**Approximate monthly cost:** $10-30 depending on activity

# Project F: Governance & Multi-Account

Provides Service Control Policies (SCPs), CloudTrail organisation trails, Security Hub, GuardDuty, and IAM Access Analyzer for multi-account governance.

## Architecture

```
AWS Organizations (Management Account)
           ↓
    ┌──────┴──────┐
    ↓             ↓
Security OU    Workloads OU
    ↓             ↓
Audit Account  Dev/Prod Accounts
    ↓
- CloudTrail Org Trail
- Security Hub (Delegated Admin)
- GuardDuty (Delegated Admin)
- IAM Access Analyzer
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with management account credentials
- AWS Organizations enabled
- Permissions: Organizations, CloudTrail, Security Hub, GuardDuty, IAM, S3

## Deployment

```bash
cd infra-terraform
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| region | AWS region | eu-west-1 |
| audit_account_id | Delegated admin account ID | - |
| allowed_regions | Regions allowed by SCP | eu-west-1, eu-central-1, us-east-1 |

## Service Control Policies

| SCP | Description |
|-----|-------------|
| scp-deny-public-s3.json | Blocks public S3 bucket ACLs |
| scp-deny-unsupported-regions.json | Restricts actions to allowed regions |
| scp-require-imdsv2.json | Requires IMDSv2 for EC2 instances |
| scp-deny-root-user.json | Blocks root user actions (except billing) |

## Security Services

- CloudTrail: Organisation-wide trail to central S3 bucket
- Security Hub: Aggregated findings across accounts
- GuardDuty: Threat detection across accounts
- IAM Access Analyzer: External access findings

## Deployment Order

1. Deploy management account infrastructure
2. Create/designate audit account
3. Enable delegated admin for Security Hub/GuardDuty
4. Attach SCPs to target OUs

## Cleanup

```bash
terraform destroy -var-file="terraform.tfvars"
```

**Note:** Disable Security Hub/GuardDuty delegated admin before destroying.

## Estimated Costs

- CloudTrail: $2/100,000 events
- Security Hub: $0.0010/finding-ingestion
- GuardDuty: Based on data analysed
- S3: Storage for CloudTrail logs

**Approximate monthly cost:** $20-50 depending on activity

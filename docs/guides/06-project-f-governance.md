# Project F: Governance & Security Services

**Exam Domain:** Domain 6 — Policies and Standards Automation
**Time:** 20-30 minutes setup, 15-20 minutes validation

---

## Prerequisites

**Required:**
- S3 state bucket from bootstrap setup

**Note:** This project deploys single-account security services. SCP examples are provided in `policies/` for exam study but require AWS Organizations to deploy.

---

## Overview

Deploy account-level security and governance:
- CloudTrail (multi-region trail with log validation)
- Security Hub (security findings aggregation)
- GuardDuty (threat detection)
- IAM Access Analyzer (external access detection)

---

## Step 1: Navigate to Project Directory

```bash
cd ~/aws-devops-pro-projects/project-f-governance-multiaccount/infra-terraform
```

## Step 2: Deploy

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**Deployment takes 3-5 minutes.**

## Step 3: Capture Outputs

```bash
terraform output -json > ../outputs.json
terraform output cloudtrail_name
terraform output guardduty_detector_id
terraform output access_analyzer_arn
```

---

## Validate CloudTrail

### Check Trail Status

```bash
aws cloudtrail describe-trails --region eu-west-1 | jq '.trailList[] | {name: .Name, isMultiRegionTrail: .IsMultiRegionTrail}'
```

### Verify Trail is Logging

```bash
aws cloudtrail get-trail-status --name account-trail --region eu-west-1 | jq '{isLogging: .IsLogging, latestDeliveryTime: .LatestDeliveryTime}'
```

### Check CloudTrail S3 Bucket

```bash
BUCKET=$(terraform output -raw cloudtrail_bucket)
aws s3 ls s3://$BUCKET --recursive | head -10
```

---

## Validate Security Hub

```bash
# Check Security Hub is enabled
aws securityhub describe-hub --region eu-west-1 | jq '{hubArn: .HubArn, subscribedAt: .SubscribedAt}'

# List enabled standards
aws securityhub get-enabled-standards --region eu-west-1 | jq '.StandardsSubscriptions[] | {standardArn: .StandardsArn, status: .StandardsStatus}'

# Get recent findings
aws securityhub get-findings --region eu-west-1 --max-items 5 | jq '.Findings[] | {title: .Title, severity: .Severity.Label}'
```

---

## Validate GuardDuty

```bash
# Get detector ID
DETECTOR_ID=$(aws guardduty list-detectors --region eu-west-1 --query 'DetectorIds[0]' --output text)

# Check detector status
aws guardduty get-detector --detector-id $DETECTOR_ID --region eu-west-1 | jq '{status: .Status, findingPublishingFrequency: .FindingPublishingFrequency}'

# List findings (if any)
aws guardduty list-findings --detector-id $DETECTOR_ID --region eu-west-1 --max-results 5 | jq '.FindingIds'
```

---

## Validate IAM Access Analyzer

```bash
# List analyzers
aws accessanalyzer list-analyzers --region eu-west-1 | jq '.analyzers[] | {name: .name, type: .type, status: .status}'

# List findings (external access detected)
aws accessanalyzer list-findings --analyzer-arn $(terraform output -raw access_analyzer_arn) --region eu-west-1 | jq '.findings[] | {resourceType: .resourceType, status: .status}'
```

---

## SCP Reference (Exam Study)

The `policies/` directory contains example SCPs. These require AWS Organizations to deploy but are important for the exam:

| Policy | Purpose |
|--------|---------|
| `scp-deny-public-s3.json` | Blocks public S3 bucket ACLs |
| `scp-deny-unsupported-regions.json` | Restricts actions to allowed regions |
| `scp-require-imdsv2.json` | Requires IMDSv2 for EC2 instances |
| `scp-deny-root-user.json` | Blocks root user actions (except billing) |

### Example SCP Structure

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyPublicS3",
    "Effect": "Deny",
    "Action": ["s3:PutBucketPublicAccessBlock"],
    "Resource": "*",
    "Condition": {
      "Bool": { "s3:PublicAccessBlockConfiguration": "false" }
    }
  }]
}
```

**Key exam points:**
- SCPs are deny-only (implicit deny, explicit allow not possible)
- SCPs don't grant permissions, only restrict them
- SCPs apply to all principals in attached accounts/OUs
- Management account is never affected by SCPs

---

## Teardown

```bash
cd ~/aws-devops-pro-projects/project-f-governance-multiaccount/infra-terraform
terraform destroy
```

### Manual Cleanup (if needed)

```bash
# Empty and delete CloudTrail bucket
BUCKET=$(terraform output -raw cloudtrail_bucket)
aws s3 rm s3://$BUCKET --recursive
aws s3 rb s3://$BUCKET

# Disable Security Hub
aws securityhub disable-security-hub --region eu-west-1

# Delete GuardDuty detector
DETECTOR_ID=$(aws guardduty list-detectors --region eu-west-1 --query 'DetectorIds[0]' --output text)
aws guardduty delete-detector --detector-id $DETECTOR_ID --region eu-west-1

# Delete Access Analyzer
aws accessanalyzer delete-analyzer --analyzer-name account-analyzer --region eu-west-1
```

---

## Key Exam Concepts Covered

- ✅ CloudTrail configuration and log validation
- ✅ Security Hub findings and standards
- ✅ GuardDuty threat detection
- ✅ IAM Access Analyzer for external access
- ✅ SCP structure and evaluation (reference only)

---

## Next Step

Proceed to [07-project-g-additional.md](07-project-g-additional.md)

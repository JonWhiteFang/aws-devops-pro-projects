# Project F: Governance & Multi-Account

**Exam Domain:** Domain 6 — Policies and Standards Automation
**Time:** 60-90 minutes setup, 30-45 minutes validation

---

## Overview

Deploy organisational governance with:
- Service Control Policies (SCPs)
- CloudTrail organisation trail
- Security Hub and GuardDuty with delegated admin
- IAM Access Analyzer
- CloudFormation StackSets

---

## Prerequisites

⚠️ **This project requires AWS Organizations.**

You need:
1. **Management account** access (root account of your organisation)
2. **At least one member account** for testing SCPs and StackSets
3. **Trusted access** enabled for relevant services

If you don't have an organisation:

```bash
aws organizations create-organization --feature-set ALL
aws organizations describe-organization | jq '.Organization | {id: .Id, masterAccountId: .MasterAccountId}'
```

---

## Step 1: Navigate to Project Directory

```bash
cd ~/aws-devops-pro-projects/project-f-governance-multiaccount/infra-terraform
```

## Step 2: Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

**Required variables:**

```hcl
aws_region   = "eu-west-1"
environment  = "dev"
project_name = "devops-pro-f"

organization_id                = "o-xxxxxxxxxx"
security_hub_admin_account_id  = "123456789012"
guardduty_admin_account_id     = "123456789012"
cloudtrail_bucket_name         = "devops-pro-cloudtrail-logs"
stackset_target_ous            = ["ou-xxxx-xxxxxxxx"]
```

## Step 3: Enable Trusted Access

```bash
aws organizations enable-aws-service-access --service-principal cloudtrail.amazonaws.com
aws organizations enable-aws-service-access --service-principal securityhub.amazonaws.com
aws organizations enable-aws-service-access --service-principal guardduty.amazonaws.com
aws organizations enable-aws-service-access --service-principal access-analyzer.amazonaws.com
aws organizations enable-aws-service-access --service-principal member.org.stacksets.cloudformation.amazonaws.com

# Verify
aws organizations list-aws-service-access-for-organization | jq '.EnabledServicePrincipals[] | .ServicePrincipal'
```

## Step 4: Deploy

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**Deployment takes 15-25 minutes.**

## Step 5: Capture Outputs

```bash
terraform output -json > ../outputs.json
terraform output cloudtrail_arn
terraform output security_hub_arn
terraform output access_analyzer_arn
```

---

## Validate SCPs

### List SCPs

```bash
aws organizations list-policies --filter SERVICE_CONTROL_POLICY | jq '.Policies[] | {id: .Id, name: .Name}'
```

### View SCP Content

```bash
SCP_ID=$(aws organizations list-policies --filter SERVICE_CONTROL_POLICY --query 'Policies[?Name==`DenyPublicS3`].Id' --output text)
aws organizations describe-policy --policy-id $SCP_ID | jq '.Policy.Content | fromjson'
```

### Check SCP Attachments

```bash
aws organizations list-targets-for-policy --policy-id $SCP_ID | jq '.Targets[] | {targetId: .TargetId, type: .Type}'
```

---

## Test SCP Enforcement

From a member account with the SCP attached:

### Test Deny Public S3 SCP

```bash
# This should fail
aws s3api put-bucket-acl --bucket test-bucket --acl public-read
# Expected: Access Denied
```

### Test Deny Unsupported Regions SCP

```bash
# This should fail if region is blocked
aws ec2 describe-instances --region ap-northeast-3
# Expected: Access Denied
```

### Test Require IMDSv2 SCP

```bash
# This should fail
aws ec2 run-instances \
  --image-id ami-12345678 \
  --instance-type t3.micro \
  --metadata-options HttpTokens=optional
# Expected: Access Denied
```

---

## Validate CloudTrail

### Check Trail Status

```bash
aws cloudtrail describe-trails | jq '.trailList[] | {name: .Name, isOrganizationTrail: .IsOrganizationTrail, isMultiRegionTrail: .IsMultiRegionTrail}'
```

### Verify Trail is Logging

```bash
TRAIL_NAME=$(terraform output -raw cloudtrail_name)
aws cloudtrail get-trail-status --name $TRAIL_NAME | jq '{isLogging: .IsLogging, latestDeliveryTime: .LatestDeliveryTime}'
```

### Check CloudTrail S3 Bucket

```bash
BUCKET=$(terraform output -raw cloudtrail_bucket)
aws s3 ls s3://$BUCKET --recursive | head -20
```

---

## Validate Security Hub

```bash
aws securityhub describe-hub | jq '{hubArn: .HubArn, subscribedAt: .SubscribedAt}'
aws securityhub get-enabled-standards | jq '.StandardsSubscriptions[] | {standardArn: .StandardsArn, status: .StandardsStatus}'
aws securityhub get-findings --max-items 5 | jq '.Findings[] | {title: .Title, severity: .Severity.Label, status: .Workflow.Status}'
aws securityhub list-organization-admin-accounts | jq '.AdminAccounts[] | {accountId: .AccountId, status: .Status}'
```

---

## Validate GuardDuty

```bash
DETECTOR_ID=$(aws guardduty list-detectors --query 'DetectorIds[0]' --output text)
aws guardduty get-detector --detector-id $DETECTOR_ID | jq '{status: .Status, findingPublishingFrequency: .FindingPublishingFrequency}'
aws guardduty list-findings --detector-id $DETECTOR_ID --max-results 5 | jq '.FindingIds'
aws guardduty list-organization-admin-accounts | jq '.AdminAccounts[] | {accountId: .AdminAccountId, status: .AdminStatus}'
```

---

## Validate IAM Access Analyzer

```bash
aws accessanalyzer list-analyzers | jq '.analyzers[] | {name: .name, type: .type, status: .status}'

ANALYZER_NAME=$(terraform output -raw access_analyzer_name)
aws accessanalyzer list-findings --analyzer-name $ANALYZER_NAME | jq '.findings[] | {resourceType: .resourceType, status: .status}'
```

---

## Validate StackSets

```bash
aws cloudformation list-stack-sets --status ACTIVE | jq '.Summaries[] | {name: .StackSetName, status: .Status}'

STACKSET_NAME=$(terraform output -raw stackset_name)
aws cloudformation list-stack-instances --stack-set-name $STACKSET_NAME | jq '.Summaries[] | {account: .Account, region: .Region, status: .Status}'
aws cloudformation list-stack-set-operations --stack-set-name $STACKSET_NAME | jq '.Summaries[] | {operationId: .OperationId, action: .Action, status: .Status}'
```

---

## Teardown

```bash
cd ~/aws-devops-pro-projects/project-f-governance-multiaccount/infra-terraform

# Delete StackSet instances first
STACKSET_NAME=$(terraform output -raw stackset_name)
aws cloudformation delete-stack-instances \
  --stack-set-name $STACKSET_NAME \
  --deployment-targets OrganizationalUnitIds=ou-xxxx-xxxxxxxx \
  --regions eu-west-1 \
  --no-retain-stacks

# Wait for deletion, then destroy
terraform destroy
```

### Manual Cleanup

```bash
# Disable delegated admins
aws securityhub disable-organization-admin-account --admin-account-id 123456789012
aws guardduty disable-organization-admin-account --admin-account-id 123456789012

# Delete organisation trail
aws cloudtrail delete-trail --name devops-pro-org-trail

# Empty and delete CloudTrail bucket
aws s3 rm s3://$BUCKET --recursive
aws s3 rb s3://$BUCKET

# Detach and delete SCPs
for SCP_ID in $(aws organizations list-policies --filter SERVICE_CONTROL_POLICY --query 'Policies[?starts_with(Name, `devops-pro`)].Id' --output text); do
  for TARGET in $(aws organizations list-targets-for-policy --policy-id $SCP_ID --query 'Targets[*].TargetId' --output text); do
    aws organizations detach-policy --policy-id $SCP_ID --target-id $TARGET
  done
  aws organizations delete-policy --policy-id $SCP_ID
done
```

---

## Key Exam Concepts Covered

- ✅ Service Control Policies (SCPs)
- ✅ SCP inheritance and evaluation
- ✅ CloudTrail organisation trails
- ✅ Security Hub organisation management
- ✅ GuardDuty organisation management
- ✅ IAM Access Analyzer (organisation scope)
- ✅ CloudFormation StackSets
- ✅ Delegated administrator accounts
- ✅ Trusted access for AWS services

---

## Next Step

Proceed to [07-project-g-additional.md](07-project-g-additional.md)

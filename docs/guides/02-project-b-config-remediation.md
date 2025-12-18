# Project B: IaC & Config Remediation

**Exam Domain:** Domain 2 — Configuration Management and IaC
**Time:** 30-45 minutes setup, 20-30 minutes validation

---

## Overview

Deploy AWS Config with:
- Managed rules for S3 public access, encrypted volumes, RDS encryption
- Custom Lambda rule for required tags
- Automated remediation via SSM Automation
- Config recorder and delivery channel

---

## Step 1: Navigate to Project Directory

```bash
cd ~/aws-devops-pro-projects/project-b-iac-config-remediation/infra-terraform
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
project_name = "devops-pro-b"

# Required tags that the custom rule will check for
required_tags = ["Owner", "Environment", "CostCenter"]

# S3 bucket for Config logs
config_bucket_prefix = "devops-pro-config"
```

## Step 3: Deploy

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**Deployment takes 5-10 minutes.**

## Step 4: Capture Outputs

```bash
terraform output -json > ../outputs.json
terraform output config_recorder_name
terraform output custom_rule_lambda_arn
```

---

## Validation

### Check Config Recorder

```bash
aws configservice describe-configuration-recorder-status | jq '.ConfigurationRecordersStatus[] | {name, recording, lastStatus}'
```

**Expected:** `recording: true`, `lastStatus: "SUCCESS"`

### List Config Rules

```bash
aws configservice describe-config-rules | jq '.ConfigRules[] | {name: .ConfigRuleName, state: .ConfigRuleState}'
```

**Expected rules:**
- `s3-bucket-public-read-prohibited`
- `encrypted-volumes`
- `rds-storage-encrypted`
- `required-tags-rule` (custom)

### Check Compliance Status

```bash
aws configservice get-compliance-summary-by-config-rule | jq '.ComplianceSummary'

aws configservice describe-compliance-by-config-rule | jq '.ComplianceByConfigRules[] | {rule: .ConfigRuleName, compliance: .Compliance.ComplianceType}'
```

---

## Test the Custom Tag Rule

### Create a Non-Compliant Resource

```bash
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $(aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --query 'Parameter.Value' --output text) \
  --instance-type t3.micro \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=test-no-tags}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance ID: $INSTANCE_ID"
```

### Trigger Rule Evaluation

```bash
aws configservice start-config-rules-evaluation --config-rule-names required-tags-rule

# Wait 1-2 minutes, then check compliance
aws configservice get-compliance-details-by-config-rule \
  --config-rule-name required-tags-rule \
  --compliance-types NON_COMPLIANT | jq '.EvaluationResults[] | {resourceId: .EvaluationResultIdentifier.EvaluationResultQualifier.ResourceId, compliance: .ComplianceType}'
```

### Verify Remediation

```bash
# Check if SSM Automation ran
aws ssm describe-automation-executions \
  --filters Key=DocumentNamePrefix,Values=AWS-AddTags \
  --query 'AutomationExecutionMetadataList[0] | {status: AutomationExecutionStatus, documentName: DocumentName}'

# Check if tags were added
aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].Tags'
```

---

## Review Config Timeline

```bash
aws configservice get-resource-config-history \
  --resource-type AWS::EC2::Instance \
  --resource-id $INSTANCE_ID \
  --limit 5 | jq '.configurationItems[] | {captureTime: .configurationItemCaptureTime, configurationStateId}'
```

---

## Teardown

```bash
# Terminate the test instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID

# Destroy Terraform resources
cd ~/aws-devops-pro-projects/project-b-iac-config-remediation/infra-terraform
terraform destroy
```

### Manual Cleanup

```bash
# Empty and delete Config S3 bucket if needed
BUCKET=$(aws s3 ls | grep devops-pro-config | awk '{print $3}')
aws s3 rm s3://$BUCKET --recursive
aws s3 rb s3://$BUCKET
```

---

## Key Exam Concepts Covered

- ✅ AWS Config recorder and delivery channel
- ✅ Managed Config rules
- ✅ Custom Config rules with Lambda
- ✅ Remediation actions with SSM Automation
- ✅ Compliance evaluation and reporting
- ✅ Resource configuration timeline

---

## Troubleshooting

### No Compliance Results Appearing

If Config shows no compliance results for your custom rule:

1. **Check Lambda logs first** - the Lambda is likely crashing:
   ```bash
   aws logs describe-log-streams --log-group-name /aws/lambda/config-required-tags --order-by LastEventTime --descending --limit 1
   # Then get the log events from that stream
   ```

2. **Common Lambda error**: `AttributeError: 'list' object has no attribute 'items'`
   - **Cause**: AWS Config sends tags as a LIST, not a dictionary
   - **Fix**: Handle tags as list format `[{'Key': 'x', 'Value': 'y'}]`

### Remediation Not Triggering

1. Check remediation execution status:
   ```bash
   aws configservice describe-remediation-execution-status --config-rule-name required-tags
   ```

2. Check SSM Automation executions:
   ```bash
   aws ssm describe-automation-executions --max-results 5
   ```

3. Verify SSM role has `ec2:CreateTags` permission

### Config Evaluation Timing

- Initial resource detection: 5-10 minutes
- Subsequent changes: 1-2 minutes
- Remediation after NON_COMPLIANT: 2-3 minutes
- **Total end-to-end**: ~5 minutes for auto-remediation

---

## Next Step

Proceed to [03-project-c-multiregion.md](03-project-c-multiregion.md)

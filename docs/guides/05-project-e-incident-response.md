# Project E: Incident Response with SSM Automation

**Exam Domain:** Domain 4 — Incident and Event Response
**Time:** 30-45 minutes setup, 20-30 minutes validation

---

## Prerequisites

**Required:**
- S3 state bucket from bootstrap setup

**Soft dependencies (will deploy but runbooks won't function without):**
- ECS cluster/service from Project A - referenced in IAM policies and SSM runbooks
- Without real ECS resources, the `RestartEcsService` runbook will fail when executed
- The EC2 recovery runbooks work independently

---

## Overview

Deploy automated incident response with:
- SSM Automation runbooks for common remediation tasks
- EventBridge rules to trigger automation from alarms
- OpsCenter integration for operational issue tracking
- Parameter Store for configuration management

---

## Step 1: Navigate to Project Directory

```bash
cd ~/aws-devops-pro-projects/project-e-incident-response-ssm/infra-terraform
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
project_name = "devops-pro-e"

ecs_cluster_name   = "devops-pro-cluster"
ecs_service_name   = "devops-pro-service"
notification_email = "your-email@example.com"
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
terraform output restart_ecs_document_name
terraform output recover_ec2_document_name
terraform output eventbridge_rule_name
```

---

## Validation

### List Custom SSM Documents

```bash
aws ssm list-documents --document-filter-list key=Owner,value=Self | jq '.DocumentIdentifiers[] | {name: .Name, type: .DocumentType}'
```

### View Document Content

```bash
aws ssm get-document --name $(terraform output -raw restart_ecs_document_name) | jq '.Content | fromjson'
aws ssm get-document --name $(terraform output -raw recover_ec2_document_name) | jq '.Content | fromjson'
aws ssm get-document --name $(terraform output -raw snapshot_document_name) | jq '.Content | fromjson'
```

---

## Test SSM Automation

### Test ECS Restart Runbook (Dry Run)

```bash
EXECUTION_ID=$(aws ssm start-automation-execution \
  --document-name $(terraform output -raw restart_ecs_document_name) \
  --parameters "ClusterName=test-cluster,ServiceName=test-service" \
  --query 'AutomationExecutionId' --output text)

echo "Execution ID: $EXECUTION_ID"

aws ssm get-automation-execution --automation-execution-id $EXECUTION_ID | jq '{status: .AutomationExecution.AutomationExecutionStatus, steps: .AutomationExecution.StepExecutions}'
```

### Test EC2 Recovery Runbook

Create a test instance:

```bash
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $(aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --query 'Parameter.Value' --output text) \
  --instance-type t3.micro \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ssm-test}]' \
  --query 'Instances[0].InstanceId' --output text)

echo "Instance ID: $INSTANCE_ID"
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
```

Run the recovery runbook:

```bash
EXECUTION_ID=$(aws ssm start-automation-execution \
  --document-name $(terraform output -raw recover_ec2_document_name) \
  --parameters "InstanceId=$INSTANCE_ID" \
  --query 'AutomationExecutionId' --output text)

watch -n 5 "aws ssm get-automation-execution --automation-execution-id $EXECUTION_ID | jq '{status: .AutomationExecution.AutomationExecutionStatus, currentStep: .AutomationExecution.CurrentStepName}'"
```

---

## Validate EventBridge Rules

### List Rules

```bash
aws events list-rules --name-prefix devops-pro-e | jq '.Rules[] | {name: .Name, state: .State}'
```

### View Rule Targets

```bash
RULE_NAME=$(terraform output -raw eventbridge_rule_name)
aws events list-targets-by-rule --rule $RULE_NAME | jq '.Targets[] | {id: .Id, arn: .Arn}'
```

---

## Test Event-Driven Automation

### Create a Test Alarm

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "test-trigger-automation" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 60 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=InstanceId,Value=$INSTANCE_ID
```

### Trigger the Alarm

```bash
aws cloudwatch set-alarm-state \
  --alarm-name "test-trigger-automation" \
  --state-value ALARM \
  --state-reason "Testing EventBridge trigger"
```

### Verify Automation Triggered

```bash
aws ssm describe-automation-executions \
  --filters Key=ExecutionStatus,Values=InProgress,Success,Failed \
  --query 'AutomationExecutionMetadataList[0:5] | [*].{DocumentName:DocumentName,Status:AutomationExecutionStatus,StartTime:ExecutionStartTime}'
```

---

## Validate OpsCenter

### Check OpsItems

```bash
aws ssm describe-ops-items --ops-item-filters Key=Status,Values=Open,Operator=Equal | jq '.OpsItemSummaries[] | {id: .OpsItemId, title: .Title, status: .Status}'
```

### Create Test OpsItem

```bash
aws ssm create-ops-item \
  --title "Test OpsItem from CLI" \
  --description "Testing OpsCenter integration" \
  --source "DevOpsPro-Testing" \
  --priority 3
```

---

## Validate Parameter Store

```bash
aws ssm describe-parameters --parameter-filters Key=Name,Values=/devops-pro-e | jq '.Parameters[] | {name: .Name, type: .Type}'

aws ssm get-parameters-by-path --path /devops-pro-e --recursive | jq '.Parameters[] | {name: .Name, value: .Value}'
```

---

## Teardown

```bash
# Clean up test resources
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws cloudwatch delete-alarms --alarm-names "test-trigger-automation"

# Delete test OpsItems
for OPSITEM in $(aws ssm describe-ops-items --ops-item-filters Key=Source,Values=DevOpsPro-Testing,Operator=Equal --query 'OpsItemSummaries[*].OpsItemId' --output text); do
  aws ssm update-ops-item --ops-item-id $OPSITEM --status Resolved
done

# Destroy Terraform
cd ~/aws-devops-pro-projects/project-e-incident-response-ssm/infra-terraform
terraform destroy
```

---

## Key Exam Concepts Covered

- ✅ SSM Automation documents (runbooks)
- ✅ Automation document steps and actions
- ✅ EventBridge rules for alarm-triggered automation
- ✅ OpsCenter for operational issue tracking
- ✅ Parameter Store for configuration
- ✅ Event-driven incident response
- ✅ Automated remediation patterns

---

## Next Step

Proceed to [06-project-f-governance.md](06-project-f-governance.md)

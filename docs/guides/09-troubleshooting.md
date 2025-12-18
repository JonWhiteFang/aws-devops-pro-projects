# Troubleshooting Guide

Common issues and solutions when deploying these projects.

---

## Terraform Issues

### Init Fails

**Error:** `Error: Failed to get existing workspaces`

```bash
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### Apply Timeout

**Error:** `Error: timeout while waiting for state to become 'ACTIVE'`

```bash
# Check resource status manually
aws ecs describe-services --cluster <cluster> --services <service>

# If stuck, destroy and recreate
terraform destroy -target=<resource>
terraform apply
```

### State Lock

**Error:** `Error: Error acquiring the state lock`

```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

---

## AWS Resource Issues

### NAT Gateway Limit

**Error:** `Error: Error creating NAT Gateway: NatGatewayLimitExceeded`

```bash
# Check limits
aws service-quotas get-service-quota --service-code vpc --quota-code L-FE5A380F

# Delete unused NAT Gateways
aws ec2 describe-nat-gateways --filter "Name=state,Values=available"
aws ec2 delete-nat-gateway --nat-gateway-id <id>
```

### ECR Repository Not Empty

**Error:** `Error: RepositoryNotEmptyException`

```bash
REPO_NAME=<repository-name>
aws ecr batch-delete-image \
  --repository-name $REPO_NAME \
  --image-ids "$(aws ecr list-images --repository-name $REPO_NAME --query 'imageIds[*]' --output json)"
aws ecr delete-repository --repository-name $REPO_NAME --force
```

### S3 Bucket Not Empty

**Error:** `Error: BucketNotEmpty`

```bash
BUCKET=<bucket-name>
aws s3 rm s3://$BUCKET --recursive

# If versioning enabled
aws s3api delete-objects --bucket $BUCKET \
  --delete "$(aws s3api list-object-versions --bucket $BUCKET --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
aws s3api delete-objects --bucket $BUCKET \
  --delete "$(aws s3api list-object-versions --bucket $BUCKET --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')"
aws s3 rb s3://$BUCKET
```

### DynamoDB Global Table Deletion

**Error:** `Error: Cannot delete table with active replicas`

```bash
TABLE_NAME=<table-name>

# Remove replicas first
aws dynamodb update-table \
  --table-name $TABLE_NAME \
  --replica-updates 'Delete={RegionName=eu-west-2}' \
  --region eu-west-1

aws dynamodb wait table-exists --table-name $TABLE_NAME --region eu-west-1
aws dynamodb delete-table --table-name $TABLE_NAME --region eu-west-1
```

### Security Group Deletion

**Error:** `Error: DependencyViolation: resource has a dependent object`

```bash
SG_ID=<security-group-id>

# Find dependent ENIs
aws ec2 describe-network-interfaces --filters "Name=group-id,Values=$SG_ID" --query 'NetworkInterfaces[*].NetworkInterfaceId'

# Delete or detach ENIs first
```

### IAM Role Deletion

**Error:** `Error: DeleteConflict: Cannot delete entity, must detach all policies first`

```bash
ROLE_NAME=<role-name>

# Detach all policies
for POLICY in $(aws iam list-attached-role-policies --role-name $ROLE_NAME --query 'AttachedPolicies[*].PolicyArn' --output text); do
  aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY
done

for POLICY in $(aws iam list-role-policies --role-name $ROLE_NAME --query 'PolicyNames[*]' --output text); do
  aws iam delete-role-policy --role-name $ROLE_NAME --policy-name $POLICY
done

aws iam delete-role --role-name $ROLE_NAME
```

---

## Pipeline Issues

### CodePipeline Stuck

**Error:** Pipeline stuck in "InProgress" state

```bash
PIPELINE=<pipeline-name>

EXECUTION_ID=$(aws codepipeline list-pipeline-executions --pipeline-name $PIPELINE --query 'pipelineExecutionSummaries[?status==`InProgress`].pipelineExecutionId' --output text)

aws codepipeline stop-pipeline-execution \
  --pipeline-name $PIPELINE \
  --pipeline-execution-id $EXECUTION_ID \
  --abandon
```

### CodeBuild Fails

```bash
# Get build logs
BUILD_ID=$(aws codebuild list-builds-for-project --project-name <project> --query 'ids[0]' --output text)
aws codebuild batch-get-builds --ids $BUILD_ID | jq '.builds[0].logs'

# View in CloudWatch
aws logs get-log-events --log-group-name /aws/codebuild/<project> --log-stream-name <stream>
```

### CodeBuild "Bad substitution" Error

**Error:** `Bad substitution` when using bash-specific syntax like `${VAR:0:7}`

CodeBuild runs commands in `/bin/sh` (POSIX shell) by default, not bash. Bash-specific syntax like substring expansion `${VAR:0:7}` will fail.

**Solutions:**

1. Use POSIX-compatible alternatives:
```yaml
# Instead of: IMAGE_TAG=${CODEBUILD_RESOLVED_SOURCE_VERSION:0:7}
# Use:
- IMAGE_TAG=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c1-7)
```

2. Or force bash at the phase level:
```yaml
phases:
  pre_build:
    run-as: root
    on-failure: ABORT
    commands:
      - IMAGE_TAG=${CODEBUILD_RESOLVED_SOURCE_VERSION:0:7}
    finally:
      - echo "done"
env:
  shell: bash  # Note: This goes under env, but may not work in all cases
```

**Recommendation:** Use POSIX-compatible commands (`cut`, `printf`, `expr`) for maximum portability.

### CodeCommit Push 403 Error

**Error:** `fatal: unable to access '...': The requested URL returned error: 403`

The git credential helper isn't picking up AWS credentials correctly.

**Solutions:**

1. Verify AWS CLI works:
```bash
aws sts get-caller-identity
aws codecommit get-repository --repository-name <repo-name>
```

2. Reset credential helper:
```bash
git config --global --unset credential.helper
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true
```

3. Use inline credentials for one-off push:
```bash
git -c credential.helper='!aws codecommit credential-helper $@' \
    -c credential.UseHttpPath=true \
    push origin main
```

4. Check IAM permissions - user needs `codecommit:GitPush` on the repository.

### CodeDeploy Rollback

```bash
# Check deployment status
DEPLOYMENT_ID=$(aws deploy list-deployments --application-name <app> --query 'deployments[0]' --output text)
aws deploy get-deployment --deployment-id $DEPLOYMENT_ID | jq '.deploymentInfo | {status, errorInformation}'

# Manual rollback
aws deploy stop-deployment --deployment-id $DEPLOYMENT_ID --auto-rollback-enabled
```

---

## ECS Issues

### Service Not Starting

```bash
# Check service events
aws ecs describe-services --cluster <cluster> --services <service> | jq '.services[0].events[:5]'

# Check task failures
aws ecs list-tasks --cluster <cluster> --service-name <service> --desired-status STOPPED
aws ecs describe-tasks --cluster <cluster> --tasks <task-arn> | jq '.tasks[0].stoppedReason'
```

### Task Definition Issues

```bash
# Get latest task definition
aws ecs describe-task-definition --task-definition <family> | jq '.taskDefinition'

# Check container logs
aws logs get-log-events --log-group-name /ecs/<service> --log-stream-name <stream>
```

---

## Config Issues

### Recorder Not Recording

```bash
# Check recorder status
aws configservice describe-configuration-recorder-status

# Start recorder
aws configservice start-configuration-recorder --configuration-recorder-name <name>
```

### Rule Evaluation Stuck

```bash
# Force evaluation
aws configservice start-config-rules-evaluation --config-rule-names <rule-name>

# Check rule status
aws configservice describe-config-rule-evaluation-status --config-rule-names <rule-name>
```

---

## Organizations Issues

### SCP Not Applying

```bash
# Check attachment
aws organizations list-policies-for-target --target-id <account-or-ou-id> --filter SERVICE_CONTROL_POLICY

# Check effective policies
aws organizations describe-effective-policy --policy-type SERVICE_CONTROL_POLICY --target-id <account-id>
```

### Trusted Access Not Enabled

```bash
# List enabled services
aws organizations list-aws-service-access-for-organization

# Enable service
aws organizations enable-aws-service-access --service-principal <service>.amazonaws.com
```

---

## General Debugging

### Check CloudTrail

```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=<event-name> \
  --max-items 5 | jq '.Events[] | {eventTime, eventName, errorCode, errorMessage}'
```

### Check Service Quotas

```bash
aws service-quotas list-service-quotas --service-code <service> | jq '.Quotas[] | {name: .QuotaName, value: .Value}'
```

### Check IAM Permissions

```bash
aws iam simulate-principal-policy \
  --policy-source-arn <role-arn> \
  --action-names <action> \
  --resource-arns <resource-arn>
```

---

## Next Step

See [10-exam-tips.md](10-exam-tips.md) for cost management and exam preparation tips.

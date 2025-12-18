# Complete Teardown

Procedures for cleaning up all projects and verifying complete removal.

---

## Teardown Order

Destroy projects in reverse order to avoid dependency issues:

```bash
# 1. Project G
cd ~/aws-devops-pro-projects/project-g-additional-topics/service-catalog && terraform destroy -auto-approve
cd ~/aws-devops-pro-projects/project-g-additional-topics/lambda-sam && sam delete --stack-name devops-pro-g-lambda --no-prompts
cd ~/aws-devops-pro-projects/project-g-additional-topics/image-builder && terraform destroy -auto-approve

# 2. Project F
cd ~/aws-devops-pro-projects/project-f-governance-multiaccount/infra-terraform && terraform destroy -auto-approve

# 3. Project E
cd ~/aws-devops-pro-projects/project-e-incident-response-ssm/infra-terraform && terraform destroy -auto-approve

# 4. Project D
cd ~/aws-devops-pro-projects/project-d-observability-cloudwatch/infra-terraform && terraform destroy -auto-approve

# 5. Project C
cd ~/aws-devops-pro-projects/project-c-multiregion-route53-dynamodb/infra-terraform && terraform destroy -auto-approve

# 6. Project B
cd ~/aws-devops-pro-projects/project-b-iac-config-remediation/infra-terraform && terraform destroy -auto-approve

# 7. Project A
cd ~/aws-devops-pro-projects/project-a-cicd-ecs-bluegreen/infra-terraform && terraform destroy -auto-approve
```

---

## Verify Complete Cleanup

```bash
echo "=== Checking for remaining resources ==="

echo "VPCs:"
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*devops-pro*" --query 'Vpcs[*].VpcId'

echo "ECS Clusters:"
aws ecs list-clusters | grep devops-pro

echo "Load Balancers:"
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `devops-pro`)].LoadBalancerArn'

echo "DynamoDB Tables:"
aws dynamodb list-tables | grep devops-pro

echo "Lambda Functions:"
aws lambda list-functions --query 'Functions[?contains(FunctionName, `devops-pro`)].FunctionName'

echo "S3 Buckets:"
aws s3 ls | grep devops-pro

echo "Log Groups:"
aws logs describe-log-groups --log-group-name-prefix /devops-pro --query 'logGroups[*].logGroupName'
```

---

## Delete Terraform State Backend (Optional)

If you created a shared state backend:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Empty and delete S3 bucket
aws s3 rm s3://devops-pro-tfstate-$ACCOUNT_ID --recursive
aws s3 rb s3://devops-pro-tfstate-$ACCOUNT_ID

# Delete DynamoDB table
aws dynamodb delete-table --table-name devops-pro-tfstate-lock
```

---

## Resource-Specific Cleanup

### ECR Repositories

```bash
REPO_NAME=<repository-name>
aws ecr batch-delete-image \
  --repository-name $REPO_NAME \
  --image-ids "$(aws ecr list-images --repository-name $REPO_NAME --query 'imageIds[*]' --output json)"
aws ecr delete-repository --repository-name $REPO_NAME --force
```

### S3 Buckets (with versioning)

```bash
BUCKET=<bucket-name>

# Delete all objects
aws s3 rm s3://$BUCKET --recursive

# Delete all versions
aws s3api delete-objects --bucket $BUCKET \
  --delete "$(aws s3api list-object-versions --bucket $BUCKET --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

# Delete all delete markers
aws s3api delete-objects --bucket $BUCKET \
  --delete "$(aws s3api list-object-versions --bucket $BUCKET --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')"

# Delete bucket
aws s3 rb s3://$BUCKET
```

### DynamoDB Global Tables

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

### IAM Roles

```bash
ROLE_NAME=<role-name>

# Detach managed policies
for POLICY in $(aws iam list-attached-role-policies --role-name $ROLE_NAME --query 'AttachedPolicies[*].PolicyArn' --output text); do
  aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY
done

# Delete inline policies
for POLICY in $(aws iam list-role-policies --role-name $ROLE_NAME --query 'PolicyNames[*]' --output text); do
  aws iam delete-role-policy --role-name $ROLE_NAME --policy-name $POLICY
done

# Remove from instance profiles
for PROFILE in $(aws iam list-instance-profiles-for-role --role-name $ROLE_NAME --query 'InstanceProfiles[*].InstanceProfileName' --output text); do
  aws iam remove-role-from-instance-profile --instance-profile-name $PROFILE --role-name $ROLE_NAME
done

# Delete role
aws iam delete-role --role-name $ROLE_NAME
```

### Route 53 Health Checks

```bash
for HC in $(aws route53 list-health-checks --query 'HealthChecks[*].Id' --output text); do
  aws route53 delete-health-check --health-check-id $HC
done
```

### CloudWatch Log Groups

```bash
for LG in $(aws logs describe-log-groups --log-group-name-prefix /devops-pro --query 'logGroups[*].logGroupName' --output text); do
  aws logs delete-log-group --log-group-name $LG
done
```

### EC2 Image Builder AMIs

```bash
for AMI in $(aws ec2 describe-images --owners self --filters "Name=tag:CreatedBy,Values=EC2 Image Builder" --query 'Images[*].ImageId' --output text); do
  aws ec2 deregister-image --image-id $AMI
done

for SNAP in $(aws ec2 describe-snapshots --owner-ids self --filters "Name=tag:CreatedBy,Values=EC2 Image Builder" --query 'Snapshots[*].SnapshotId' --output text); do
  aws ec2 delete-snapshot --snapshot-id $SNAP
done
```

---

## Next Step

If you encountered issues, see [09-troubleshooting.md](09-troubleshooting.md)

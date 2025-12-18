# Project A: CI/CD with ECS Blue/Green Deployments

**Exam Domain:** Domain 1 — SDLC Automation
**Time:** 45-60 minutes setup, 30-45 minutes validation

---

## Overview

Deploy a complete CI/CD pipeline with:
- ECS Fargate cluster running a Node.js application
- CodePipeline with Source → Build → Approval → Deploy → Test stages
- CodeDeploy blue/green deployments with automatic rollback
- ECR repository with lifecycle policies
- SNS notifications for pipeline events

---

## Step 1: Navigate to Project Directory

```bash
cd ~/aws-devops-pro-projects/project-a-cicd-ecs-bluegreen/infra-terraform
```

## Step 2: Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

**Required variables:**

```hcl
aws_region     = "eu-west-1"
environment    = "dev"
project_name   = "devops-pro-a"

# VPC Configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["eu-west-1a", "eu-west-1b"]

# ECS Configuration
ecs_task_cpu    = 256
ecs_task_memory = 512
desired_count   = 2

# Container Configuration
container_port = 3000

# Notification email (for pipeline alerts)
notification_email = "your-email@example.com"
```

## Step 3: Initialise Terraform

```bash
terraform init
```

**Expected output:**
```
Terraform has been successfully initialized!
```

## Step 4: Review the Plan

```bash
terraform plan -out=tfplan
```

**Review the output carefully.** You should see approximately:
- 1 VPC, 2 public subnets, 2 private subnets
- 1 Internet Gateway, 2 NAT Gateways
- 1 ECS Cluster, 1 Task Definition, 1 Service
- 1 ALB, 2 Target Groups, 2 Listeners
- 1 ECR Repository
- 1 CodeCommit Repository
- 2 CodeBuild Projects
- 1 CodePipeline
- 1 CodeDeploy Application and Deployment Group
- Multiple IAM Roles and Policies
- 1 SNS Topic

## Step 5: Apply the Configuration

```bash
terraform apply tfplan
```

**This takes 10-15 minutes.** The longest resources are:
- NAT Gateways (~3-5 minutes each)
- ECS Service stabilisation (~3-5 minutes)

## Step 6: Capture Outputs

```bash
terraform output -json > ../outputs.json

terraform output alb_dns
terraform output ecr_repository_url
terraform output codecommit_clone_url
terraform output pipeline_name
```

---

## Validation

### Check ECS Service

```bash
CLUSTER=$(terraform output -raw ecs_cluster_name)

aws ecs list-services --cluster $CLUSTER
aws ecs describe-services --cluster $CLUSTER --services $(terraform output -raw ecs_service_name)
```

**Expected:** Service should show `runningCount` equal to `desiredCount`.

### Test the Application

```bash
ALB_DNS=$(terraform output -raw alb_dns)

curl -s http://$ALB_DNS/health | jq .
curl -s http://$ALB_DNS/ | jq .
```

**Expected response:**
```json
{
  "status": "healthy",
  "version": "1.0.0"
}
```

### Verify Pipeline

```bash
PIPELINE=$(terraform output -raw pipeline_name)

aws codepipeline get-pipeline-state --name $PIPELINE | jq '.stageStates[] | {stageName, latestExecution}'
```

---

## Trigger a Pipeline Execution

### Clone the CodeCommit Repository

```bash
REPO_URL=$(terraform output -raw codecommit_clone_url)

cd ~/aws-devops-pro-projects/project-a-cicd-ecs-bluegreen
git clone $REPO_URL app-repo
cd app-repo
```

### Push Application Code

```bash
cp -r ../app/* .

git add .
git commit -m "Initial application code"
git push origin main
```

### Monitor Pipeline Execution

```bash
watch -n 10 "aws codepipeline get-pipeline-state --name $PIPELINE | jq '.stageStates[] | {stageName, status: .latestExecution.status}'"
```

**Pipeline stages:**
1. **Source** — Pulls from CodeCommit
2. **Build** — Builds Docker image, pushes to ECR
3. **Approval** — Manual approval gate (approve in console)
4. **Deploy** — Blue/green deployment via CodeDeploy
5. **Test** — Integration tests

### Approve the Deployment

```bash
aws codepipeline get-pipeline-state --name $PIPELINE | jq '.stageStates[] | select(.stageName=="Approval")'

# Or approve via console:
# https://console.aws.amazon.com/codesuite/codepipeline/pipelines/$PIPELINE/view
```

---

## Verify Blue/Green Deployment

```bash
aws deploy list-deployments --application-name $(terraform output -raw codedeploy_app_name) | jq '.deployments[0]'

DEPLOYMENT_ID=$(aws deploy list-deployments --application-name $(terraform output -raw codedeploy_app_name) --query 'deployments[0]' --output text)
aws deploy get-deployment --deployment-id $DEPLOYMENT_ID | jq '.deploymentInfo | {status, deploymentOverview}'
```

---

## Test Rollback (Optional)

To test automatic rollback:

1. Modify the application to return a 500 error on `/health`
2. Push the change
3. Approve the deployment
4. Watch CodeDeploy detect the failure and rollback

---

## Teardown

```bash
cd ~/aws-devops-pro-projects/project-a-cicd-ecs-bluegreen/infra-terraform
terraform destroy
```

**Type `yes` when prompted. Teardown takes 10-15 minutes.**

### Verify Teardown

```bash
aws ecs list-clusters | jq '.clusterArns | length'
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `devops-pro-a`)]'
aws ecr describe-repositories --query 'repositories[?contains(repositoryName, `devops-pro-a`)]'
```

### Manual Cleanup (Required)

CodeBuild auto-creates CloudWatch Log Groups not managed by Terraform:

```bash
# Delete CodeBuild log groups (always required)
aws logs delete-log-group --log-group-name /aws/codebuild/devops-pro-a-build --region eu-west-1
aws logs delete-log-group --log-group-name /aws/codebuild/devops-pro-a-test --region eu-west-1
```

### Manual Cleanup (if needed)

```bash
# Delete ECR images
aws ecr batch-delete-image --repository-name <repo-name> --image-ids "$(aws ecr list-images --repository-name <repo-name> --query 'imageIds[*]' --output json)"
aws ecr delete-repository --repository-name <repo-name> --force

# Delete CodeCommit repository
aws codecommit delete-repository --repository-name <repo-name>
```

---

## Key Exam Concepts Covered

- ✅ CodePipeline stages and actions
- ✅ CodeBuild buildspec.yml structure
- ✅ CodeDeploy blue/green deployment configuration
- ✅ ECS task definitions and services
- ✅ Application Load Balancer target groups
- ✅ ECR lifecycle policies
- ✅ Approval gates in pipelines
- ✅ Automatic rollback on deployment failure
- ✅ SNS notifications for pipeline events

---

## Next Step

Proceed to [02-project-b-config-remediation.md](02-project-b-config-remediation.md)

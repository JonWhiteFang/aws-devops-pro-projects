# Project A: CI/CD with ECS Blue/Green Deployments

Demonstrates a complete CI/CD pipeline deploying a containerised Node.js application to ECS Fargate with CodeDeploy blue/green deployments.

## Architecture

```
CodeCommit → CodePipeline → CodeBuild → ECR → CodeDeploy → ECS Fargate
                              ↓                    ↓
                         Build Image         Blue/Green Deploy
                                                   ↓
                                            ALB Target Groups
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- Permissions: ECS, ECR, CodePipeline, CodeBuild, CodeDeploy, IAM, VPC, ALB, S3, CloudWatch

## Deployment

```bash
cd infra-terraform

# Initialise Terraform
terraform init

# Review plan
terraform plan -var-file="terraform.tfvars"

# Apply
terraform apply -var-file="terraform.tfvars"
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| region | AWS region | eu-west-1 |
| project | Project name prefix | demo-ecs-bluegreen |
| app_port | Application port | 8080 |

## Outputs

| Output | Description |
|--------|-------------|
| alb_dns | ALB DNS name for accessing the application |
| ecr_repository_url | ECR repository URL for pushing images |
| pipeline_name | CodePipeline name |
| codecommit_clone_url | CodeCommit repository clone URL |

## Testing the Deployment

1. Push code to CodeCommit repository
2. Pipeline triggers automatically
3. Access application via ALB DNS output

```bash
curl http://$(terraform output -raw alb_dns)/health
curl http://$(terraform output -raw alb_dns)/
```

## Blue/Green Deployment Flow

1. CodeBuild builds new Docker image and pushes to ECR
2. CodeDeploy creates new (green) task set
3. Traffic shifts to green target group
4. Blue tasks terminate after 5 minutes
5. Auto-rollback on failure

## Cleanup

```bash
terraform destroy -var-file="terraform.tfvars"
```

### Manual Cleanup (Required)

CodeBuild auto-creates CloudWatch Log Groups that are not managed by Terraform. Delete them after `terraform destroy`:

```bash
aws logs delete-log-group --log-group-name /aws/codebuild/devops-pro-a-build --region eu-west-1
aws logs delete-log-group --log-group-name /aws/codebuild/devops-pro-a-test --region eu-west-1
```

## Learnings & Key Implementation Details

### taskdef.json Placeholder Substitution

The `taskdef.json` uses placeholders that must be substituted during the CodeBuild phase:
- `<EXECUTION_ROLE_ARN>` - ECS task execution role
- `<TASK_ROLE_ARN>` - ECS task role  
- `${AWS_REGION}` - AWS region for CloudWatch logs
- `REPLACE_ME_ECR_URI:latest` - ECR image URI with tag

The `buildspec.yml` uses `sed` commands in the `post_build` phase to perform these substitutions.

### CodeBuild Environment Variables

The following environment variables must be passed to CodeBuild for the substitution to work:
- `EXECUTION_ROLE_ARN` - From `aws_iam_role.ecs_task_execution.arn`
- `TASK_ROLE_ARN` - From `aws_iam_role.ecs_task_role.arn`
- `AWS_DEFAULT_REGION` - From `var.region`

### Automatic Rollback Timing

CodeDeploy blue/green deployments take 2-3+ minutes to detect health check failures:
1. ~30-60s for ECS to start new tasks
2. ~30-60s for container health checks to fail (3 retries × 10s)
3. ~30-60s for ALB to mark targets unhealthy
4. CodeDeploy then triggers automatic rollback

Do not manually stop deployments during this window if testing rollback behaviour.

## Estimated Costs

- ECS Fargate: ~$0.04/hour (2 tasks, 0.25 vCPU, 0.5GB)
- ALB: ~$0.02/hour + LCU charges
- NAT Gateway: Not used (public subnets)
- CodeBuild: Pay per build minute
- ECR: Storage costs for images

**Approximate monthly cost:** $30-50 for light usage

# Cost Management Guide

Strategies for minimizing AWS costs while using these projects.

## Cost Breakdown by Project

| Project | Primary Cost Drivers | Est. Daily Cost | Est. Monthly Cost |
|---------|---------------------|-----------------|-------------------|
| A | ECS Fargate, ALB, NAT Gateway | $5-10 | $150-300 |
| B | Config rules, Lambda | $1-2 | $30-60 |
| C | Multi-region ALBs, NAT Gateways, DynamoDB | $8-15 | $240-450 |
| D | CloudWatch, Synthetics canary | $2-5 | $60-150 |
| E | EventBridge, SSM (minimal) | $1-2 | $30-60 |
| F | CloudTrail, Security Hub, GuardDuty | $2-5 | $60-150 |
| G | Image Builder (on-demand), Service Catalog | $3-8 | $90-240 |

## Cost Optimization Strategies

### 1. Deploy One Project at a Time

```bash
# Deploy
cd project-a-cicd-ecs-bluegreen/infra-terraform
terraform apply

# Learn and experiment

# Destroy before moving to next project
terraform destroy
```

### 2. Use Smaller Instance Types

Edit `terraform.tfvars` to use smaller instances where possible:

```hcl
# Project A - ECS
container_cpu    = 256   # Instead of 512
container_memory = 512   # Instead of 1024

# Project G - Image Builder
instance_types = ["t3.micro"]  # Instead of t3.medium
```

### 3. Disable Expensive Features During Learning

```hcl
# Project D - Disable Synthetics canary
# Comment out synthetics.tf or set:
canary_enabled = false

# Project C - Skip Route 53 (requires hosted zone)
create_route53_records = false
```

### 4. Schedule Resources

For non-production learning:

```bash
# Stop ECS service at night
aws ecs update-service --cluster demo --service app --desired-count 0

# Resume in morning
aws ecs update-service --cluster demo --service app --desired-count 1
```

### 5. Use AWS Free Tier Where Possible

These services have free tier allowances:
- Lambda: 1M requests/month
- DynamoDB: 25 GB storage, 25 RCU/WCU
- CloudWatch: 10 custom metrics, 5 GB logs
- S3: 5 GB storage
- Config: First 100 rule evaluations/month

## Monitoring Your Costs

### Enable Cost Alerts

```bash
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget '{
    "BudgetName": "DevOps-Pro-Projects",
    "BudgetLimit": {"Amount": "50", "Unit": "USD"},
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }' \
  --notifications-with-subscribers '[{
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80
    },
    "Subscribers": [{
      "SubscriptionType": "EMAIL",
      "Address": "your-email@example.com"
    }]
  }]'
```

### Check Current Costs

```bash
# Today's costs
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-%d),End=$(date -v+1d +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

## Cleanup Checklist

Before destroying, verify these resources are removed:

- [ ] ECS services scaled to 0
- [ ] NAT Gateways (expensive if left running)
- [ ] ALBs in all regions
- [ ] CloudWatch Synthetics canaries
- [ ] Image Builder pipelines (cancel running builds)
- [ ] S3 buckets emptied (required for deletion)

```bash
# Full cleanup for a project
cd project-X/infra-terraform
terraform destroy -auto-approve
```

## Cost-Free Alternatives for Learning

1. **LocalStack** — Run AWS services locally (limited but free)
2. **AWS Skill Builder** — Free labs with temporary AWS accounts
3. **Terraform Plan Only** — Review what would be created without deploying

```bash
# Review without deploying
terraform plan -out=tfplan
terraform show tfplan
```

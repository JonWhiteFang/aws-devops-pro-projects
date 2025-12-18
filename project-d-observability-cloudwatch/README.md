# Project D: Observability with CloudWatch

Creates CloudWatch dashboards, metric alarms, log insights queries, Synthetics canaries, and demonstrates custom metrics publishing.

## Architecture

```
Application → CloudWatch Logs → Metric Filters → Alarms → SNS
     ↓
Custom Metrics (EMF) → CloudWatch Metrics → Dashboard
     ↓
X-Ray Traces → Service Map
     ↓
Synthetics Canary → Availability Monitoring → Alarms
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- Permissions: CloudWatch, SNS, Lambda, IAM, S3, Synthetics

### Dependencies from Other Projects

**Required:**
- S3 state bucket (`devops-pro-tfstate-<account-id>`) from bootstrap setup
- CloudWatch Log Group (`/ecs/demo-api`) - created by Project A, or create manually:
  ```bash
  aws logs create-log-group --log-group-name /ecs/demo-api --region eu-west-1
  ```

**Optional (dashboard/alarms will deploy but show no data):**
- ALB from Project A (for ALB metrics)
- ECS cluster/service from Project A (for ECS metrics)
- `canary_endpoint` variable (if empty, Synthetics canary is skipped)

## Deployment

```bash
cd infra-terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Variables

| Variable | Description | Required |
|----------|-------------|----------|
| region | AWS region | Yes (default: eu-west-1) |
| alb_name | ALB name for metrics (e.g., app/my-alb/abc123) | Yes |
| ecs_cluster | ECS cluster name | Yes |
| ecs_service | ECS service name | Yes |
| log_group_name | CloudWatch Log Group | Yes (default: /ecs/demo-api) |
| canary_endpoint | URL for Synthetics canary | No (empty = skip canary) |

## Features

- **CloudWatch Dashboard** with ALB and ECS metrics
- **Metric Alarms**:
  - ALB 5xx errors (threshold)
  - ECS CPU utilization (threshold)
  - Request count anomaly detection
  - Canary failure (if enabled)
- **Composite Alarm** combining ALB + ECS conditions
- **Log Metric Filters** for error counting and latency extraction
- **X-Ray Configuration**:
  - Custom sampling rule (5% rate)
  - Trace groups for errors and slow requests
- **CloudWatch Synthetics** (optional) for endpoint monitoring
- **EMF Support** for custom metrics via structured logs

## Outputs

| Output | Description |
|--------|-------------|
| dashboard_url | Direct link to CloudWatch dashboard |
| dashboard_name | Dashboard name for CLI commands |
| sns_topic_arn | SNS topic for alarm notifications |
| log_group_name | Log group being monitored |
| alb_5xx_alarm_name | Name of ALB 5xx alarm |
| canary_name | Synthetics canary name (if enabled) |
| canary_bucket | S3 bucket for canary artifacts (if enabled) |

## Log Insights Queries

Example queries included in `logs_insights_queries.md`:
- Error rate analysis
- Latency percentiles
- Top error messages
- Request patterns

## Custom Metrics with EMF

Use `app-metrics-example.py` to see EMF format:

```bash
python3 app-metrics-example.py
```

EMF logs are automatically parsed by CloudWatch to extract metrics.

## Troubleshooting

### Metric Filter Not Working
- Simple patterns like `ERROR` don't support dimensions
- Dimensions require structured log patterns with field extraction

### Synthetics Canary Fails
- Ensure `canary_endpoint` is publicly accessible
- Check canary logs in `/aws/lambda/cwsyn-<canary-name>*`
- Runtime must be current (syn-nodejs-puppeteer-9.1 or later)

### Alarms Stuck in INSUFFICIENT_DATA
- Metrics need data points to evaluate
- Generate traffic to ALB or wait for ECS metrics
- Use `aws cloudwatch set-alarm-state` to test alarm actions

## Cleanup

```bash
terraform destroy
```

If Synthetics was enabled, also clean up:
```bash
CANARY_BUCKET=$(terraform output -raw canary_bucket)
aws s3 rm s3://$CANARY_BUCKET --recursive
aws s3 rb s3://$CANARY_BUCKET
```

## Estimated Costs

- CloudWatch Dashboards: $3/month per dashboard
- Alarms: $0.10/month per alarm
- Logs: $0.50/GB ingested
- Metrics: First 10 custom metrics free
- Synthetics: $0.0012 per canary run

**Approximate monthly cost:** $10-25 (depending on Synthetics usage)

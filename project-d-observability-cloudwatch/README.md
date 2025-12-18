# Project D: Observability with CloudWatch

Creates CloudWatch dashboards, metric alarms, log insights queries, and demonstrates custom metrics publishing.

## Architecture

```
Application → CloudWatch Logs → Metric Filters → Alarms → SNS
     ↓
Custom Metrics (EMF) → CloudWatch Metrics → Dashboard
     ↓
X-Ray Traces → Service Map
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- Permissions: CloudWatch, SNS, Lambda, IAM

## Deployment

```bash
cd infra-terraform
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| region | AWS region | eu-west-1 |
| alb_name | ALB name for metrics | - |
| ecs_cluster | ECS cluster name | - |
| ecs_service | ECS service name | - |

## Features

- CloudWatch Dashboard with ALB and ECS metrics
- Metric alarms for 5xx errors and CPU utilisation
- Composite alarm combining multiple conditions
- Anomaly detection alarm
- Log metric filters for error counting
- CloudWatch Logs Insights query examples
- Custom metrics via Embedded Metric Format (EMF)

## Log Insights Queries

Example queries included in `logs_insights_queries.md`:
- Error rate analysis
- Latency percentiles
- Top error messages
- Request patterns

## Custom Metrics

Use `app-metrics-example.py` to publish custom metrics:

```bash
python app-metrics-example.py
```

## Cleanup

```bash
terraform destroy -var-file="terraform.tfvars"
```

## Estimated Costs

- CloudWatch Dashboards: $3/month per dashboard
- Alarms: $0.10/month per alarm
- Logs: $0.50/GB ingested
- Metrics: First 10 custom metrics free

**Approximate monthly cost:** $10-20

# Project D: Observability with CloudWatch

**Exam Domain:** Domain 3 — Monitoring and Logging
**Time:** 30-45 minutes setup, 20-30 minutes validation

---

## Overview

Deploy comprehensive observability with:
- CloudWatch Dashboard with multiple widget types
- Metric alarms (threshold, composite, anomaly detection)
- Log metric filters
- X-Ray tracing configuration
- CloudWatch Synthetics canary
- Custom metrics via Embedded Metric Format (EMF)

---

## Step 1: Navigate to Project Directory

```bash
cd ~/aws-devops-pro-projects/project-d-observability-cloudwatch/infra-terraform
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
project_name = "devops-pro-d"

alert_email = "your-email@example.com"

# Application endpoints (use placeholders if Project A not running)
alb_arn_suffix   = "app/my-alb/1234567890"
ecs_cluster_name = "devops-pro-cluster"
ecs_service_name = "devops-pro-service"

# Synthetics target
canary_target_url = "https://example.com"
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
terraform output dashboard_url
terraform output sns_topic_arn
terraform output canary_name
```

---

## Validation

### View Dashboard

```bash
echo "https://console.aws.amazon.com/cloudwatch/home?region=eu-west-1#dashboards:name=$(terraform output -raw dashboard_name)"
```

### Verify Dashboard Widgets

```bash
aws cloudwatch get-dashboard --dashboard-name $(terraform output -raw dashboard_name) | jq '.DashboardBody | fromjson | .widgets[] | {type, properties: .properties.title}'
```

### List Metric Alarms

```bash
aws cloudwatch describe-alarms --alarm-name-prefix devops-pro-d | jq '.MetricAlarms[] | {name: .AlarmName, state: .StateValue, type: .Statistic}'
```

### Check Composite Alarm

```bash
aws cloudwatch describe-alarms --alarm-types CompositeAlarm | jq '.CompositeAlarms[] | {name: .AlarmName, state: .StateValue, rule: .AlarmRule}'
```

### Check Anomaly Detection Alarm

```bash
aws cloudwatch describe-alarms --alarm-name-prefix devops-pro-d-anomaly | jq '.MetricAlarms[] | {name: .AlarmName, threshold: .ThresholdMetricId}'
```

---

## Test Alarm Triggering

```bash
# Set alarm to ALARM state
aws cloudwatch set-alarm-state \
  --alarm-name $(terraform output -raw alb_5xx_alarm_name) \
  --state-value ALARM \
  --state-reason "Testing alarm notification"

# Check your email for SNS notification

# Reset to OK
aws cloudwatch set-alarm-state \
  --alarm-name $(terraform output -raw alb_5xx_alarm_name) \
  --state-value OK \
  --state-reason "Test complete"
```

---

## Validate Log Metric Filters

### List Metric Filters

```bash
aws logs describe-metric-filters --log-group-name $(terraform output -raw log_group_name) | jq '.metricFilters[] | {name: .filterName, pattern: .filterPattern}'
```

### Test Metric Filter

```bash
# Put a test log event
aws logs put-log-events \
  --log-group-name $(terraform output -raw log_group_name) \
  --log-stream-name test-stream \
  --log-events timestamp=$(date +%s000),message="ERROR: Test error message"

# Wait a minute, then check the metric
aws cloudwatch get-metric-statistics \
  --namespace "DevOpsPro/Application" \
  --metric-name "ErrorCount" \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum
```

---

## Validate X-Ray

### Check Sampling Rules

```bash
aws xray get-sampling-rules | jq '.SamplingRuleRecords[] | {name: .SamplingRule.RuleName, rate: .SamplingRule.FixedRate}'
```

### Check Trace Groups

```bash
aws xray get-groups | jq '.Groups[] | {name: .GroupName, filterExpression: .FilterExpression}'
```

---

## Validate CloudWatch Synthetics

### Check Canary Status

```bash
aws synthetics describe-canaries | jq '.Canaries[] | {name: .Name, status: .Status.State, schedule: .Schedule.Expression}'
```

### Get Canary Runs

```bash
CANARY_NAME=$(terraform output -raw canary_name)
aws synthetics get-canary-runs --name $CANARY_NAME | jq '.CanaryRuns[] | {status: .Status.State, startTime: .Timeline.Started}'
```

---

## Test Custom Metrics with EMF

### Run the EMF Publisher Script

```bash
cd ~/aws-devops-pro-projects/project-d-observability-cloudwatch/scripts
pip install boto3
python emf_publisher.py
```

### Verify Custom Metrics

```bash
aws cloudwatch list-metrics --namespace "DevOpsPro/Application" | jq '.Metrics[] | {name: .MetricName, dimensions: .Dimensions}'

aws cloudwatch get-metric-statistics \
  --namespace "DevOpsPro/Application" \
  --metric-name "RequestLatency" \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Average
```

---

## Run Logs Insights Queries

```bash
QUERY_ID=$(aws logs start-query \
  --log-group-name $(terraform output -raw log_group_name) \
  --start-time $(date -u -d '1 hour ago' +%s) \
  --end-time $(date -u +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20' \
  --query 'queryId' --output text)

sleep 5
aws logs get-query-results --query-id $QUERY_ID | jq '.results'
```

---

## Teardown

```bash
cd ~/aws-devops-pro-projects/project-d-observability-cloudwatch/infra-terraform
terraform destroy
```

### Manual Cleanup

```bash
CANARY_NAME=$(terraform output -raw canary_name)
CANARY_BUCKET=$(aws s3 ls | grep synthetics | awk '{print $3}')
aws s3 rm s3://$CANARY_BUCKET --recursive
aws s3 rb s3://$CANARY_BUCKET
aws logs delete-log-group --log-group-name /aws/synthetics/$CANARY_NAME
```

---

## Key Exam Concepts Covered

- ✅ CloudWatch Dashboard creation and widgets
- ✅ Metric alarms (threshold-based)
- ✅ Composite alarms
- ✅ Anomaly detection alarms
- ✅ Log metric filters
- ✅ CloudWatch Logs Insights queries
- ✅ X-Ray sampling rules and trace groups
- ✅ CloudWatch Synthetics canaries
- ✅ Embedded Metric Format (EMF)
- ✅ SNS alarm notifications

---

## Next Step

Proceed to [05-project-e-incident-response.md](05-project-e-incident-response.md)

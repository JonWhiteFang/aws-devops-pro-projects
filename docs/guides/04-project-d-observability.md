# Project D: Observability with CloudWatch

**Exam Domain:** Domain 3 — Monitoring and Logging
**Time:** 30-45 minutes setup, 20-30 minutes validation

---

## Prerequisites

**Required:**
- S3 state bucket from bootstrap setup
- CloudWatch Log Group `/ecs/demo-api` - either:
  - Run Project A first (creates ECS infrastructure + log group), OR
  - Create manually: `aws logs create-log-group --log-group-name /ecs/demo-api --region eu-west-1`

**Optional (will deploy but show no data without):**
- ALB/ECS from Project A (for metrics)
- `canary_endpoint` variable (if empty, Synthetics canary skipped)

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
region         = "eu-west-1"
alb_name       = "app/demo-ecs-bluegreen-alb/1234567890abcdef"
ecs_cluster    = "demo-ecs-bluegreen-cluster"
ecs_service    = "demo-ecs-bluegreen-service"
log_group_name = "/ecs/demo-api"

# Optional: Synthetics canary endpoint (leave empty to skip)
canary_endpoint = "http://your-alb-dns.eu-west-1.elb.amazonaws.com/health"
```

**To get ALB name from Project A:**
```bash
aws elbv2 describe-load-balancers --names demo-ecs-bluegreen-alb \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text | sed 's/.*:loadbalancer\///'
```

## Step 3: Deploy

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**Deployment takes 2-5 minutes (longer if Synthetics canary enabled).**

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
terraform output dashboard_url
# Or directly:
echo "https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#dashboards:name=app-observability"
```

### List Metric Alarms

```bash
aws cloudwatch describe-alarms --query 'MetricAlarms[].{Name:AlarmName,State:StateValue}' --output table
```

### Check Composite Alarm

```bash
aws cloudwatch describe-alarms --alarm-types CompositeAlarm \
  --query 'CompositeAlarms[].{Name:AlarmName,State:StateValue,Rule:AlarmRule}' --output table
```

### Check Anomaly Detection Alarm

```bash
aws cloudwatch describe-alarms --alarm-name-prefix Request-Count-Anomaly \
  --query 'MetricAlarms[].{Name:AlarmName,State:StateValue}' --output table
```

---

## Test Alarm Triggering

```bash
# Set alarm to ALARM state
aws cloudwatch set-alarm-state \
  --alarm-name ALB-5xx-High \
  --state-value ALARM \
  --state-reason "Testing alarm notification"

# Check alarm state
aws cloudwatch describe-alarms --alarm-names ALB-5xx-High \
  --query 'MetricAlarms[0].StateValue' --output text

# Reset to OK
aws cloudwatch set-alarm-state \
  --alarm-name ALB-5xx-High \
  --state-value OK \
  --state-reason "Test complete"
```

---

## Validate Log Metric Filters

### List Metric Filters

```bash
aws logs describe-metric-filters --log-group-name /ecs/demo-api \
  --query 'metricFilters[].{Name:filterName,Pattern:filterPattern}' --output table
```

### Test Metric Filter

```bash
# Create test log stream
aws logs create-log-stream --log-group-name /ecs/demo-api --log-stream-name test-stream 2>/dev/null || true

# Put a test log event with ERROR
TIMESTAMP=$(date +%s)000
aws logs put-log-events \
  --log-group-name /ecs/demo-api \
  --log-stream-name test-stream \
  --log-events "[{\"timestamp\":$TIMESTAMP,\"message\":\"ERROR: Test error message\"}]"

# Wait a minute, then check the metric
aws cloudwatch get-metric-statistics \
  --namespace "DemoApp" \
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
aws xray get-sampling-rules \
  --query 'SamplingRuleRecords[?SamplingRule.RuleName!=`Default`].SamplingRule.{Name:RuleName,Rate:FixedRate}' \
  --output table
```

### Check Trace Groups

```bash
aws xray get-groups --query 'Groups[].{Name:GroupName,Filter:FilterExpression}' --output table
```

---

## Validate CloudWatch Synthetics

### Check Canary Status

```bash
aws synthetics describe-canaries \
  --query 'Canaries[].{Name:Name,Status:Status.State,Schedule:Schedule.Expression}' --output table
```

### Get Canary Runs

```bash
aws synthetics get-canary-runs --name app-heartbeat \
  --query 'CanaryRuns[0:3].{Status:Status.State,Started:Timeline.Started}' --output table
```

---

## Test Custom Metrics with EMF

### Publish EMF Metric

```bash
# Create log stream for EMF
aws logs create-log-stream --log-group-name /ecs/demo-api --log-stream-name emf-test 2>/dev/null || true

# Publish EMF formatted log (CloudWatch extracts metrics automatically)
TIMESTAMP=$(date +%s)000
aws logs put-log-events \
  --log-group-name /ecs/demo-api \
  --log-stream-name emf-test \
  --log-events "[{\"timestamp\":$TIMESTAMP,\"message\":\"{\\\"_aws\\\":{\\\"Timestamp\\\":$TIMESTAMP,\\\"CloudWatchMetrics\\\":[{\\\"Namespace\\\":\\\"DemoApp\\\",\\\"Dimensions\\\":[[\\\"Service\\\"]],\\\"Metrics\\\":[{\\\"Name\\\":\\\"Latency\\\",\\\"Unit\\\":\\\"Milliseconds\\\"}]}]},\\\"Service\\\":\\\"api\\\",\\\"Latency\\\":150}\"}]"

echo "EMF metric published! CloudWatch will extract to DemoApp namespace."
```

### Verify Custom Metrics

```bash
aws cloudwatch list-metrics --namespace "DemoApp" \
  --query 'Metrics[].{Name:MetricName,Dimensions:Dimensions}' --output table
```

---

## Run Logs Insights Queries

```bash
START_TIME=$(($(date +%s) - 3600))
END_TIME=$(date +%s)

QUERY_ID=$(aws logs start-query \
  --log-group-name /ecs/demo-api \
  --start-time $START_TIME \
  --end-time $END_TIME \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20' \
  --query 'queryId' --output text)

sleep 5
aws logs get-query-results --query-id $QUERY_ID --query 'results[*][0:2]' --output table
```

---

## Teardown

```bash
cd ~/aws-devops-pro-projects/project-d-observability-cloudwatch/infra-terraform
terraform destroy
```

### Manual Cleanup (if Synthetics was enabled)

```bash
# Get canary bucket name
CANARY_BUCKET=$(terraform output -raw canary_bucket 2>/dev/null)
if [ -n "$CANARY_BUCKET" ]; then
  aws s3 rm s3://$CANARY_BUCKET --recursive
  aws s3 rb s3://$CANARY_BUCKET
  aws logs delete-log-group --log-group-name /aws/lambda/cwsyn-app-heartbeat* 2>/dev/null || true
fi
```

---

## Troubleshooting

### Metric Filter Not Working
- Simple patterns like `ERROR` don't support dimensions
- Dimensions require structured log patterns with field extraction
- Check filter pattern syntax in CloudWatch console

### Synthetics Canary Fails
- Ensure `canary_endpoint` is accessible from AWS (public URL)
- Check canary logs in `/aws/lambda/cwsyn-<canary-name>*`
- Runtime must be current (syn-nodejs-puppeteer-9.1 or later)

### Alarms Stuck in INSUFFICIENT_DATA
- Metrics need data points to evaluate
- Generate traffic to ALB or wait for ECS metrics
- Use `set-alarm-state` to test alarm actions

---

## Key Exam Concepts Covered

- ✅ CloudWatch Dashboard creation and widgets
- ✅ Metric alarms (threshold-based)
- ✅ Composite alarms (AND/OR logic)
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

# Quick Reference

Common commands and patterns used across all projects.

## Terraform Commands

```bash
# Initialize with shared backend
terraform init -backend-config=../../backend.hcl

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Destroy all resources
terraform destroy

# Format code
terraform fmt -recursive

# Validate syntax
terraform validate

# Show current state
terraform show

# List resources in state
terraform state list

# Import existing resource
terraform import aws_s3_bucket.example bucket-name
```

## AWS CLI Quick Commands

### Identity & Region

```bash
# Who am I?
aws sts get-caller-identity

# Current region
aws configure get region
```

### ECS (Project A)

```bash
# List clusters
aws ecs list-clusters

# List services
aws ecs list-services --cluster CLUSTER_NAME

# Force new deployment
aws ecs update-service --cluster CLUSTER --service SERVICE --force-new-deployment

# View task logs
aws logs tail /ecs/SERVICE_NAME --follow
```

### Config (Project B)

```bash
# List rules
aws configservice describe-config-rules

# Get compliance
aws configservice get-compliance-details-by-config-rule --config-rule-name RULE_NAME

# Start evaluation
aws configservice start-config-rules-evaluation --config-rule-names RULE_NAME
```

### Route 53 (Project C)

```bash
# List hosted zones
aws route53 list-hosted-zones

# List health checks
aws route53 list-health-checks

# Get health check status
aws route53 get-health-check-status --health-check-id ID
```

### CloudWatch (Project D)

```bash
# List dashboards
aws cloudwatch list-dashboards

# Get alarm state
aws cloudwatch describe-alarms --alarm-names ALARM_NAME

# Query logs
aws logs start-query \
  --log-group-name LOG_GROUP \
  --start-time $(date -v-1H +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/'
```

### SSM (Project E)

```bash
# List automation executions
aws ssm describe-automation-executions

# Start automation
aws ssm start-automation-execution \
  --document-name DOCUMENT_NAME \
  --parameters '{"InstanceId":["i-xxx"]}'

# Get parameter
aws ssm get-parameter --name /app/config --with-decryption
```

### Security Services (Project F)

```bash
# Security Hub findings
aws securityhub get-findings --filters '{"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"}]}'

# GuardDuty findings
aws guardduty list-findings --detector-id DETECTOR_ID

# Access Analyzer findings
aws accessanalyzer list-findings --analyzer-name ANALYZER_NAME
```

## Common Patterns

### Get Terraform Outputs

```bash
# Single output
terraform output alb_dns_name

# All outputs as JSON
terraform output -json
```

### Debug Terraform

```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform apply

# Disable
unset TF_LOG
```

### Check Resource Dependencies

```bash
terraform graph | dot -Tpng > graph.png
```

## Useful Aliases

Add to `~/.zshrc` or `~/.bashrc`:

```bash
alias tf='terraform'
alias tfi='terraform init -backend-config=../../backend.hcl'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfv='terraform validate'
alias tff='terraform fmt -recursive'
```

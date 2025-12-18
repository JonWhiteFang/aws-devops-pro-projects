# Project B: IaC & Config Remediation

Implements AWS Config rules (managed and custom) with automated remediation via SSM Automation.

## Architecture

```
AWS Config Recorder → Config Rules → Non-Compliant Detection
                                            ↓
                                    Remediation Action
                                            ↓
                                    SSM Automation Document
                                            ↓
                                    Auto-Tag Resources
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- Permissions: Config, Lambda, SSM, IAM, S3, CloudWatch Logs

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

## Config Rules

| Rule | Type | Description |
|------|------|-------------|
| s3-bucket-public-read-prohibited | Managed | Checks S3 buckets aren't publicly readable |
| required-tags | Custom Lambda | Checks resources have Owner and Environment tags |
| encrypted-volumes | Managed | Checks EBS volumes are encrypted |
| rds-encryption-enabled | Managed | Checks RDS instances are encrypted |

## Remediation

Non-compliant EC2 instances missing required tags are automatically remediated:
1. Config detects non-compliance
2. Remediation action triggers SSM Automation
3. SSM document adds default tags (Owner=AutoFix, Environment=Dev)

## Testing

1. Create an EC2 instance without Owner/Environment tags
2. Wait for Config evaluation (or trigger manually)
3. Observe remediation adding tags automatically

## Cleanup

```bash
terraform destroy -var-file="terraform.tfvars"
```

## Estimated Costs

- AWS Config: ~$2/month per rule
- Lambda: Minimal (invoked per evaluation)
- S3: Storage for Config logs

**Approximate monthly cost:** $10-20

## Learnings

### AWS Managed Policy Availability
- `arn:aws:iam::aws:policy/service-role/AWSConfigRole` may not exist in all AWS accounts/partitions
- **Solution**: Use inline IAM policies instead of managed policies for Config service role
- Required permissions: `config:*`, `s3:GetBucketVersioning`, `s3:ListBucket`, `s3:PutObject`, `s3:GetBucketAcl`

### Config Evaluation Timing
- Config can take **5-10 minutes** to detect new resources and trigger rule evaluations
- Manual trigger via `start-config-rules-evaluation` doesn't significantly speed up initial detection
- Config must first record the resource in its inventory before rules can evaluate it
- **Exam tip**: Understand Config is eventually consistent, not real-time

### Automatic Remediation Behavior
- Remediation only triggers AFTER Config evaluates a resource as NON_COMPLIANT
- Remediation configuration parameters:
  - `automatic = true` - enables auto-remediation
  - `maximum_automatic_attempts = 3` - retry limit
  - `retry_attempt_seconds = 60` - wait between retries
- SSM Automation documents must have proper IAM permissions to modify resources

### Lambda CloudWatch Logs
- Lambda auto-creates log group `/aws/lambda/<function-name>` on first invocation
- Unlike CodeBuild (Project A), Lambda log groups ARE deleted when Lambda function is destroyed
- **No manual cleanup required** for Lambda logs in this project

### Custom Config Rules
- Custom Lambda rules require:
  - Lambda permission for `config.amazonaws.com` to invoke
  - Lambda IAM role with `config:PutEvaluations` permission
  - Proper event source configuration (`ConfigurationItemChangeNotification`)
- Lambda must call `config.put_evaluations()` with compliance result
- Input parameters passed as JSON in `input_parameters` field

### Config Tag Data Format (Critical!)
- **AWS Config sends tags as a LIST**, not a dictionary
- Format: `[{'Key': 'Name', 'Value': 'foo'}, {'Key': 'Env', 'Value': 'dev'}]`
- Common mistake: assuming `tags.items()` will work - it won't!
- Always handle both formats defensively:
  ```python
  tags = config_item.get('tags', [])
  tag_list = tags if isinstance(tags, list) else [{'Key':k,'Value':v} for k,v in tags.items()]
  ```
- **Debugging tip**: If Config shows no compliance results, check Lambda CloudWatch logs for errors

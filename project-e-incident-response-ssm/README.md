# Project E: Incident Response with SSM Automation

Automates incident response by triggering SSM Automation runbooks from CloudWatch alarm state changes.

## Architecture

```
CloudWatch Alarm → EventBridge Rule → SSM Automation
                                           ↓
                                    Remediation Actions
                                    (Restart ECS, Recover EC2, etc.)
                                           ↓
                                    OpsCenter OpsItem
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- Permissions: SSM, EventBridge, CloudWatch, ECS, EC2, OpsCenter, IAM

### Dependencies from Other Projects

**Required:**
- S3 state bucket (`devops-pro-tfstate-<account-id>`) from bootstrap setup

**Soft dependencies (will deploy but runbooks won't function without):**
- ECS cluster/service from Project A - referenced in IAM policies and SSM runbooks
- Without real ECS resources, the `RestartEcsService` runbook will fail when executed

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
| ecs_cluster | ECS cluster name | - |
| ecs_service | ECS service name | - |

## SSM Automation Runbooks

| Runbook | Description |
|---------|-------------|
| RestartEcsService | Forces new ECS deployment |
| RecoverEC2Instance | Stops and starts EC2 instance |
| CreateSnapshotBeforeAction | Creates EBS snapshot before remediation |

## EventBridge Rules

| Rule | Trigger | Action |
|------|---------|--------|
| AlarmToRestartEcs | CloudWatch alarm → ALARM | Restart ECS service |
| EC2StateChange | EC2 instance stopped unexpectedly | Recover EC2 |

## OpsCenter Integration

Non-critical alarms create OpsItems for manual review:
- Automatic OpsItem creation
- Links to relevant runbooks
- Severity based on alarm

## Testing

1. Trigger a CloudWatch alarm manually
2. Observe EventBridge rule execution
3. Check SSM Automation execution history
4. Verify remediation action completed

## Cleanup

```bash
terraform destroy -var-file="terraform.tfvars"
```

## Estimated Costs

- SSM Automation: Free tier covers most usage
- EventBridge: $1/million events
- OpsCenter: Free

**Approximate monthly cost:** <$5

# Exam Question Mapping

Maps common AWS DevOps Professional exam question topics to projects in this repository.

## Domain 1: SDLC Automation (22%)

| Question Topic | Project | Relevant Files |
|----------------|---------|----------------|
| CodePipeline stages and actions | A | `codepipeline.tf` |
| Blue/green deployments | A | `ecs.tf`, `codepipeline.tf` |
| Approval gates in pipelines | A | `codepipeline.tf` (Manual Approval stage) |
| CodeBuild buildspec | A | `app/buildspec.yml` |
| CodeDeploy deployment configurations | A | `ecs.tf` (CodeDeployDefault.ECSAllAtOnce) |
| Rollback strategies | A | `ecs.tf` (auto_rollback_configuration) |
| ECR lifecycle policies | A | `ecr.tf` |
| Pipeline notifications | A | `codepipeline.tf` (SNS, CodeStar Notifications) |
| Lambda canary deployments | G | `lambda-sam/template.yaml` |
| SAM deployment preferences | G | `lambda-sam/template.yaml` |

## Domain 2: Configuration Management & IaC (17%)

| Question Topic | Project | Relevant Files |
|----------------|---------|----------------|
| AWS Config rules | B | `config.tf` |
| Custom Config rules with Lambda | B | `config.tf`, `lambda_required_tags.py` |
| Config remediation | B | `config.tf` (aws_config_remediation_configuration) |
| SSM Automation documents | B, E | `config.tf`, `ssm_automation.tf` |
| Terraform state management | All | `backend.tf` files |
| Infrastructure drift detection | B | AWS Config recorder |
| CloudFormation StackSets | F | `stacksets.tf` |
| Service Catalog | G | `service-catalog/main.tf` |

## Domain 3: Monitoring & Logging (15%)

| Question Topic | Project | Relevant Files |
|----------------|---------|----------------|
| CloudWatch dashboards | D | `dashboard.tf` |
| Metric alarms | D | `dashboard.tf` |
| Composite alarms | D | `dashboard.tf` |
| Anomaly detection | D | `dashboard.tf` |
| Log metric filters | D | `dashboard.tf` |
| CloudWatch Logs Insights | D | `logs_insights_queries.md` |
| Custom metrics (EMF) | D | `app-metrics-example.py` |
| X-Ray tracing | D | `xray.tf` |
| Synthetics canaries | D | `synthetics.tf` |
| Container Insights | A | `ecs.tf` (containerInsights setting) |

## Domain 4: Incident & Event Response (15%)

| Question Topic | Project | Relevant Files |
|----------------|---------|----------------|
| EventBridge rules | E | `ssm_automation.tf` |
| SSM Automation runbooks | E | `ssm_automation.tf` |
| OpsCenter OpsItems | E | `ssm_automation.tf` |
| Automated remediation | B, E | `config.tf`, `ssm_automation.tf` |
| Parameter Store | E | `ssm_automation.tf` |
| Alarm-triggered actions | E | EventBridge rules |
| Pre/post deployment hooks | G | `lambda-sam/hooks/` |

## Domain 5: High Availability & DR (18%)

| Question Topic | Project | Relevant Files |
|----------------|---------|----------------|
| Route 53 failover routing | C | `route53.tf` |
| Route 53 health checks | C | `route53.tf` |
| Latency-based routing | C | `route53.tf` |
| DynamoDB Global Tables | C | `dynamodb.tf` |
| Multi-region architecture | C | All files |
| AWS Backup | C | `backup.tf` |
| Cross-region replication | C | `backup.tf` (copy_action) |
| RTO/RPO considerations | C | README.md |
| Blue/green with zero downtime | A | `ecs.tf` |

## Domain 6: Policies & Standards (13%)

| Question Topic | Project | Relevant Files |
|----------------|---------|----------------|
| Service Control Policies | F | `policies/*.json` |
| AWS Organizations | F | `main.tf` |
| CloudTrail organization trails | F | `main.tf` |
| Security Hub | F | `main.tf` |
| GuardDuty | F | `main.tf` |
| IAM Access Analyzer | F | `main.tf` |
| IMDSv2 enforcement | F | `scp-require-imdsv2.json` |
| Preventive controls | F | All SCPs |
| Detective controls | F | Security Hub, GuardDuty |
| Tag policies | F | `stacksets.tf` (TagOptions) |

## Sample Question Scenarios

### Scenario 1: Pipeline Failure
> "A deployment failed and rolled back. How do you investigate?"

**Relevant:** Project A
- Check CodePipeline execution history
- Review CodeBuild logs
- Check CodeDeploy deployment events
- Review CloudWatch alarms that triggered rollback

### Scenario 2: Compliance Violation
> "EC2 instances are being launched without required tags. How do you enforce compliance?"

**Relevant:** Project B
- AWS Config custom rule with Lambda
- Automatic remediation via SSM Automation
- See `config.tf` and `lambda_required_tags.py`

### Scenario 3: Regional Failover
> "Primary region is experiencing issues. How does traffic fail over?"

**Relevant:** Project C
- Route 53 health checks detect failure
- Failover routing policy redirects to secondary
- DynamoDB Global Table ensures data availability
- See `route53.tf`

### Scenario 4: Alarm Fatigue
> "Too many alarms are firing. How do you reduce noise?"

**Relevant:** Project D
- Composite alarms to combine conditions
- Anomaly detection for dynamic thresholds
- See `dashboard.tf`

### Scenario 5: Automated Recovery
> "Service is unhealthy. How do you automatically recover?"

**Relevant:** Project E
- EventBridge rule triggers on alarm
- SSM Automation restarts ECS service
- OpsItem created for tracking
- See `ssm_automation.tf`

### Scenario 6: Multi-Account Governance
> "How do you prevent public S3 buckets across all accounts?"

**Relevant:** Project F
- SCP attached to organizational units
- See `scp-deny-public-s3.json`
- Security Hub for detection

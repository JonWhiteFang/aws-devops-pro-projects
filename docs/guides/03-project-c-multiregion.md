# Project C: Multi-Region with Route 53 & DynamoDB

**Exam Domain:** Domain 5 — High Availability, Fault Tolerance, and Disaster Recovery
**Time:** 45-60 minutes setup, 30-45 minutes validation

---

## Overview

Deploy multi-region architecture with:
- VPCs in two regions (eu-west-1, eu-west-2)
- Lambda functions behind ALBs in each region
- DynamoDB Global Table replicated across regions
- Route 53 health checks and failover routing
- AWS Backup with cross-region replication

---

## Prerequisites

You need a registered domain in Route 53 or the ability to create a hosted zone.

```bash
aws route53 list-hosted-zones | jq '.HostedZones[] | {name: .Name, id: .Id}'
```

If you don't have a domain, you can still deploy the infrastructure but skip the Route 53 DNS configuration.

---

## Step 1: Navigate to Project Directory

```bash
cd ~/aws-devops-pro-projects/project-c-multiregion-route53-dynamodb/infra-terraform
```

## Step 2: Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

**Required variables:**

```hcl
primary_region   = "eu-west-1"
secondary_region = "eu-west-2"
environment      = "dev"
project_name     = "devops-pro-c"

# Route 53 (if you have a domain)
domain_name    = "example.com"
hosted_zone_id = "Z1234567890"

# VPC Configuration
primary_vpc_cidr   = "10.1.0.0/16"
secondary_vpc_cidr = "10.2.0.0/16"

# DynamoDB
dynamodb_table_name = "devops-pro-global"
```

## Step 3: Deploy

```bash
terraform init

# Deploy primary region first
terraform plan -out=tfplan -target=module.primary
terraform apply tfplan

# Deploy secondary region
terraform plan -out=tfplan -target=module.secondary
terraform apply tfplan

# Deploy global resources
terraform plan -out=tfplan
terraform apply tfplan
```

**Total deployment takes 15-25 minutes.**

## Step 4: Capture Outputs

```bash
terraform output -json > ../outputs.json

terraform output primary_alb_dns
terraform output secondary_alb_dns
terraform output dynamodb_table_name
terraform output route53_record_name
```

---

## Validation

### Test Primary Region

```bash
PRIMARY_ALB=$(terraform output -raw primary_alb_dns)
curl -s http://$PRIMARY_ALB/health | jq .
curl -s http://$PRIMARY_ALB/ | jq .
```

### Test Secondary Region

```bash
SECONDARY_ALB=$(terraform output -raw secondary_alb_dns)
curl -s http://$SECONDARY_ALB/health | jq .
curl -s http://$SECONDARY_ALB/ | jq .
```

### Verify DynamoDB Global Table

```bash
aws dynamodb describe-table \
  --table-name $(terraform output -raw dynamodb_table_name) \
  --region eu-west-1 | jq '.Table | {tableName: .TableName, status: .TableStatus, replicas: .Replicas}'

aws dynamodb describe-table \
  --table-name $(terraform output -raw dynamodb_table_name) \
  --region eu-west-2 | jq '.Table | {tableName: .TableName, status: .TableStatus}'
```

### Test Global Table Replication

```bash
# Write to primary region
aws dynamodb put-item \
  --table-name $(terraform output -raw dynamodb_table_name) \
  --item '{"pk": {"S": "test-item"}, "data": {"S": "written-to-primary"}}' \
  --region eu-west-1

# Read from secondary region
sleep 5
aws dynamodb get-item \
  --table-name $(terraform output -raw dynamodb_table_name) \
  --key '{"pk": {"S": "test-item"}}' \
  --region eu-west-2 | jq '.Item'
```

---

## Validate Route 53

### Check Health Checks

```bash
aws route53 list-health-checks | jq '.HealthChecks[] | {id: .Id, type: .HealthCheckConfig.Type, fqdn: .HealthCheckConfig.FullyQualifiedDomainName}'
```

### Check Health Check Status

```bash
PRIMARY_HC=$(aws route53 list-health-checks --query 'HealthChecks[?contains(HealthCheckConfig.FullyQualifiedDomainName, `eu-west-1`)].Id' --output text)

aws route53 get-health-check-status --health-check-id $PRIMARY_HC | jq '.HealthCheckObservations[0] | {region: .Region, status: .StatusReport.Status}'
```

### Test DNS Resolution

```bash
DOMAIN=$(terraform output -raw route53_record_name)
dig +short $DOMAIN
curl -s http://$DOMAIN/health | jq .
```

---

## Test Failover

### Simulate Primary Region Failure

```bash
# Get primary ALB security group
PRIMARY_SG=$(aws elbv2 describe-load-balancers \
  --names devops-pro-c-primary-alb \
  --region eu-west-1 \
  --query 'LoadBalancers[0].SecurityGroups[0]' \
  --output text)

# Block inbound traffic
aws ec2 revoke-security-group-ingress \
  --group-id $PRIMARY_SG \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --region eu-west-1
```

### Monitor Failover

```bash
# Watch health check status (30-60 seconds to detect)
watch -n 10 "aws route53 get-health-check-status --health-check-id $PRIMARY_HC | jq '.HealthCheckObservations[0].StatusReport.Status'"

# Once unhealthy, test DNS
dig +short $DOMAIN
# Should resolve to secondary region
```

### Restore Primary Region

```bash
aws ec2 authorize-security-group-ingress \
  --group-id $PRIMARY_SG \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --region eu-west-1
```

---

## Verify AWS Backup

```bash
aws backup list-backup-vaults | jq '.BackupVaultList[] | {name: .BackupVaultName}'
aws backup list-backup-plans | jq '.BackupPlansList[] | {name: .BackupPlanName, id: .BackupPlanId}'
aws backup list-backup-jobs --by-state COMPLETED | jq '.BackupJobs[] | {resourceArn: .ResourceArn, status: .State}'
```

---

## Teardown

```bash
cd ~/aws-devops-pro-projects/project-c-multiregion-route53-dynamodb/infra-terraform
terraform destroy
```

### Manual Cleanup (if needed)

```bash
# Delete DynamoDB Global Table replicas first
aws dynamodb update-table \
  --table-name devops-pro-global \
  --replica-updates 'Delete={RegionName=eu-west-2}' \
  --region eu-west-1

aws dynamodb wait table-exists --table-name devops-pro-global --region eu-west-1
aws dynamodb delete-table --table-name devops-pro-global --region eu-west-1

# Delete Route 53 health checks
for HC in $(aws route53 list-health-checks --query 'HealthChecks[*].Id' --output text); do
  aws route53 delete-health-check --health-check-id $HC
done

# Delete backup vaults
aws backup delete-backup-vault --backup-vault-name devops-pro-c-vault --region eu-west-1
aws backup delete-backup-vault --backup-vault-name devops-pro-c-vault-dr --region eu-west-2
```

---

## Key Exam Concepts Covered

- ✅ Multi-region VPC architecture
- ✅ DynamoDB Global Tables
- ✅ Route 53 health checks
- ✅ Failover routing policy
- ✅ Latency-based routing
- ✅ Cross-region disaster recovery
- ✅ AWS Backup with cross-region copy
- ✅ RPO and RTO considerations

---

## Next Step

Proceed to [04-project-d-observability.md](04-project-d-observability.md)

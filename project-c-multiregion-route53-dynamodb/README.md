# Project C: Multi-Region with Route 53 & DynamoDB Global Tables

Sets up multi-region active-passive architecture with DNS failover and globally replicated data.

## Architecture

```
                    Route 53 (Failover Policy)
                           ↓
            ┌──────────────┴──────────────┐
            ↓                             ↓
    Region A (Primary)            Region B (Secondary)
         ALB                           ALB
          ↓                             ↓
       Lambda                        Lambda
          ↓                             ↓
    DynamoDB ←──── Global Table ────→ DynamoDB
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- Route 53 hosted zone for your domain
- Permissions: Route 53, DynamoDB, Lambda, ALB, VPC, IAM

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
| region_a | Primary region | eu-west-1 |
| region_b | Secondary region | eu-west-2 |
| domain_name | Route 53 hosted zone domain | example.com |

## Features

- DynamoDB Global Table with automatic replication
- Route 53 health checks on both regions
- Failover routing policy (primary/secondary)
- Lambda functions behind ALBs in each region

## Failover Behaviour

1. Route 53 health checks monitor ALB endpoints
2. If primary fails health check, traffic routes to secondary
3. DynamoDB Global Table ensures data consistency
4. RTO: ~60 seconds (DNS TTL + health check interval)

## Testing Failover

1. Access `app.yourdomain.com` - should hit primary
2. Stop/break primary ALB or Lambda
3. Wait for health check failure (~90 seconds)
4. Traffic automatically routes to secondary

## Cleanup

```bash
terraform destroy -var-file="terraform.tfvars"
```

## Estimated Costs

- DynamoDB: Pay per request + replication
- Route 53: $0.50/hosted zone + $0.50/health check
- ALB: ~$0.02/hour per region
- Lambda: Pay per invocation

**Approximate monthly cost:** $30-50

## Key Learnings

### DynamoDB Global Table Replication
- Cross-region replication latency is ~2 seconds (eu-west-1 → eu-west-2)
- Plan for eventual consistency in application logic
- Streams must be enabled (`NEW_AND_OLD_IMAGES`) for replication

### ALB Provisioning
- ALB creation takes ~3 minutes per load balancer
- Factor this into CI/CD pipeline timeouts
- Lambda target groups require `lambda_multi_value_headers_enabled = true`

### Route 53 Optional Deployment
- All Route 53 resources use `count = var.enable_route53 ? 1 : 0`
- Allows testing multi-region setup without owning a domain
- Set `enable_route53 = false` in terraform.tfvars to skip DNS

### Failover Simulation
- Quick test: Block port 80 on ALB security group ingress
- Simulates regional failure without destroying infrastructure
- Restore by re-adding the ingress rule
- Useful for validating failover behaviour before production

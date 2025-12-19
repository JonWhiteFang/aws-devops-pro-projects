# Security Considerations

Security best practices and considerations for each project. These projects are designed for learning — production deployments require additional hardening.

## General Security Practices

### Secrets Management

**Current State:** Some projects use Secrets Manager (Project A), but many use inline values for simplicity.

**Production Recommendation:**
- Store all secrets in AWS Secrets Manager or Parameter Store (SecureString)
- Rotate secrets automatically
- Never commit secrets to version control

```hcl
# Good: Reference from Secrets Manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db.id
}

# Bad: Hardcoded
variable "db_password" {
  default = "password123"  # Never do this
}
```

### IAM Policies

**Current State:** Projects use scoped policies but some use wildcards for simplicity.

**Production Recommendation:**
- Follow least privilege principle
- Use resource-level permissions where possible
- Avoid `*` in resource ARNs
- Use IAM Access Analyzer to identify unused permissions

```hcl
# Good: Scoped to specific resources
resource "aws_iam_policy" "example" {
  policy = jsonencode({
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "${aws_s3_bucket.data.arn}/*"
    }]
  })
}

# Avoid: Overly permissive
resource "aws_iam_policy" "bad" {
  policy = jsonencode({
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:*"]
      Resource = "*"
    }]
  })
}
```

### Encryption

**Current State:** Most projects enable encryption where configured.

**Production Recommendation:**
- Enable encryption at rest for all storage (S3, EBS, RDS, DynamoDB)
- Enable encryption in transit (TLS/HTTPS)
- Use KMS customer-managed keys for sensitive workloads
- Enable CloudTrail log file validation

---

## Project-Specific Security

### Project A: CI/CD

| Component | Current | Production Recommendation |
|-----------|---------|---------------------------|
| ECR | Scan on push enabled | Add lifecycle policies, enable immutable tags |
| CodeBuild | Uses service role | Restrict to specific ECR repos, add VPC |
| Secrets | Secrets Manager | Rotate automatically, audit access |
| ALB | HTTP listener | Add HTTPS with ACM certificate |
| ECS | Public subnets | Move to private subnets with NAT |

**Additional Hardening:**
```hcl
# Enable ECR image scanning
resource "aws_ecr_repository" "app" {
  image_scanning_configuration {
    scan_on_push = true
  }
  
  # Prevent tag overwrites
  image_tag_mutability = "IMMUTABLE"
}

# CodeBuild in VPC
resource "aws_codebuild_project" "build" {
  vpc_config {
    vpc_id             = aws_vpc.main.id
    subnets            = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.codebuild.id]
  }
}
```

### Project B: Config Remediation

| Component | Current | Production Recommendation |
|-----------|---------|---------------------------|
| Config S3 | Basic bucket | Enable versioning, encryption, access logging |
| Lambda | Basic execution role | Add VPC, restrict permissions |
| SSM Automation | Service role | Scope to specific resource types |

**Additional Hardening:**
```hcl
# Secure Config bucket
resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  bucket = aws_s3_bucket.config_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.config.arn
    }
  }
}
```

### Project C: Multi-Region

| Component | Current | Production Recommendation |
|-----------|---------|---------------------------|
| ALB | Public facing | Add WAF, enable access logs |
| Lambda | Public subnets | Move to private subnets |
| DynamoDB | On-demand | Enable point-in-time recovery |
| Route 53 | Basic health checks | Add latency-based routing, DNSSEC |

**Additional Hardening:**
```hcl
# Add WAF to ALB
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# Enable DynamoDB PITR
resource "aws_dynamodb_table" "main" {
  point_in_time_recovery {
    enabled = true
  }
}
```

### Project D: Observability

| Component | Current | Production Recommendation |
|-----------|---------|---------------------------|
| CloudWatch Logs | Basic retention | Set retention policy, encrypt with KMS |
| SNS | Unencrypted | Enable server-side encryption |
| Synthetics | Public endpoint | Test internal endpoints via VPC |

**Additional Hardening:**
```hcl
# Encrypt CloudWatch Logs
resource "aws_cloudwatch_log_group" "app" {
  retention_in_days = 30
  kms_key_id        = aws_kms_key.logs.arn
}

# Encrypt SNS
resource "aws_sns_topic" "alerts" {
  kms_master_key_id = aws_kms_key.sns.id
}
```

### Project E: Incident Response

| Component | Current | Production Recommendation |
|-----------|---------|---------------------------|
| SSM Documents | Account-scoped | Add approval workflows for critical actions |
| EventBridge | Basic rules | Add dead-letter queues |
| Parameter Store | Standard | Use SecureString for sensitive values |

**Additional Hardening:**
```hcl
# SSM with approval
resource "aws_ssm_document" "critical_action" {
  content = jsonencode({
    schemaVersion = "0.3"
    mainSteps = [{
      name   = "approve"
      action = "aws:approve"
      inputs = {
        Approvers = ["arn:aws:iam::ACCOUNT:role/Approvers"]
      }
    }]
  })
}
```

### Project F: Governance

| Component | Current | Production Recommendation |
|-----------|---------|---------------------------|
| CloudTrail | Single account | Organization trail with log file validation |
| S3 (CloudTrail) | Basic | Object lock, cross-account replication |
| Security Hub | Basic | Enable all standards, configure findings export |

**Additional Hardening:**
```hcl
# CloudTrail with integrity validation
resource "aws_cloudtrail" "main" {
  enable_log_file_validation = true
  is_multi_region_trail      = true
  
  # Encrypt logs
  kms_key_id = aws_kms_key.cloudtrail.arn
  
  # Log data events
  event_selector {
    read_write_type           = "All"
    include_management_events = true
    
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3"]
    }
  }
}
```

### Project G: Additional Topics

| Component | Current | Production Recommendation |
|-----------|---------|---------------------------|
| Image Builder | Basic AMI | Add CIS hardening, vulnerability scanning |
| Service Catalog | Basic constraints | Add budget constraints, approval workflows |
| SAM Lambda | Basic function | Add VPC, reserved concurrency |

---

## Security Checklist

Before deploying to production:

- [ ] All S3 buckets have encryption enabled
- [ ] All S3 buckets block public access
- [ ] CloudTrail is enabled with log validation
- [ ] VPC Flow Logs are enabled
- [ ] Security groups follow least privilege
- [ ] IAM policies are scoped to specific resources
- [ ] Secrets are stored in Secrets Manager/Parameter Store
- [ ] KMS keys are used for sensitive data
- [ ] ALBs have WAF attached
- [ ] HTTPS is enforced (HTTP redirects to HTTPS)
- [ ] GuardDuty is enabled
- [ ] Security Hub is enabled with compliance standards
- [ ] CloudWatch alarms exist for security events
- [ ] Backup and recovery procedures are tested

## Compliance Considerations

These projects can help demonstrate compliance with:

| Framework | Relevant Projects |
|-----------|-------------------|
| CIS AWS Foundations | F (Security Hub), B (Config) |
| SOC 2 | F (CloudTrail, GuardDuty), D (Monitoring) |
| PCI DSS | F (Access controls), A (Change management) |
| HIPAA | F (Encryption, audit), B (Config rules) |

Note: Compliance requires additional controls beyond what these projects demonstrate.

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "audit_account_id" {
  type        = string
  description = "Account ID for delegated admin (Security Hub, GuardDuty)"
}

variable "allowed_regions" {
  type    = list(string)
  default = ["eu-west-1", "eu-central-1", "us-east-1"]
}

data "aws_caller_identity" "current" {}
data "aws_organizations_organization" "org" {}

# S3 Bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "cloudtrail-org-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail.arn
        Condition = {
          StringEquals = { "aws:SourceArn" = "arn:aws:cloudtrail:${var.region}:${data.aws_caller_identity.current.account_id}:trail/org-trail" }
        }
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.region}:${data.aws_caller_identity.current.account_id}:trail/org-trail"
          }
        }
      }
    ]
  })
}

# CloudTrail Organization Trail
resource "aws_cloudtrail" "org" {
  name                       = "org-trail"
  s3_bucket_name             = aws_s3_bucket.cloudtrail.id
  is_organization_trail      = true
  is_multi_region_trail      = true
  enable_log_file_validation = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

# Security Hub - Enable in management account
resource "aws_securityhub_account" "main" {}

# Security Hub - Delegated Admin
resource "aws_securityhub_organization_admin_account" "delegated" {
  admin_account_id = var.audit_account_id
  depends_on       = [aws_securityhub_account.main]
}

# GuardDuty - Enable in management account
resource "aws_guardduty_detector" "main" {
  enable = true
}

# GuardDuty - Delegated Admin
resource "aws_guardduty_organization_admin_account" "delegated" {
  admin_account_id = var.audit_account_id
  depends_on       = [aws_guardduty_detector.main]
}

# IAM Access Analyzer - Organization level
resource "aws_accessanalyzer_analyzer" "org" {
  analyzer_name = "org-analyzer"
  type          = "ORGANIZATION"
}

# SCPs
resource "aws_organizations_policy" "deny_public_s3" {
  name        = "deny-public-s3"
  description = "Deny public S3 bucket ACLs"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/../policies/scp-deny-public-s3.json")
}

resource "aws_organizations_policy" "deny_unsupported_regions" {
  name        = "deny-unsupported-regions"
  description = "Deny actions in unsupported regions"
  type        = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "DenyUnsupportedRegions"
      Effect   = "Deny"
      Action   = "*"
      Resource = "*"
      Condition = {
        StringNotEquals = {
          "aws:RequestedRegion" = var.allowed_regions
        }
      }
    }]
  })
}

resource "aws_organizations_policy" "require_imdsv2" {
  name        = "require-imdsv2"
  description = "Require IMDSv2 for EC2 instances"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/../policies/scp-require-imdsv2.json")
}

resource "aws_organizations_policy" "deny_root_user" {
  name        = "deny-root-user"
  description = "Deny root user actions except billing"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/../policies/scp-deny-root-user.json")
}

# Outputs
output "cloudtrail_bucket" {
  value = aws_s3_bucket.cloudtrail.bucket
}

output "cloudtrail_name" {
  value = aws_cloudtrail.org.name
}

output "access_analyzer_arn" {
  value = aws_accessanalyzer_analyzer.org.arn
}

output "scp_deny_public_s3_id" {
  value = aws_organizations_policy.deny_public_s3.id
}

output "scp_deny_unsupported_regions_id" {
  value = aws_organizations_policy.deny_unsupported_regions.id
}

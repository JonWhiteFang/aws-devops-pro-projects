data "aws_caller_identity" "current" {}

# Service Catalog Portfolio
resource "aws_servicecatalog_portfolio" "main" {
  name          = "DevOps-Approved-Products"
  description   = "Pre-approved infrastructure products for development teams"
  provider_name = "Platform Team"
}

# IAM role for launching products
resource "aws_iam_role" "launch" {
  name = "ServiceCatalogLaunchRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "servicecatalog.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "launch" {
  role = aws_iam_role.launch.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStacks",
          "cloudformation:UpdateStack",
          "cloudformation:SetStackPolicy"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:PutBucketPolicy",
          "s3:PutBucketTagging",
          "s3:PutEncryptionConfiguration",
          "s3:PutBucketVersioning",
          "s3:PutBucketPublicAccessBlock"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["sns:*"]
        Resource = "*"
      }
    ]
  })
}

# Launch constraint
resource "aws_servicecatalog_constraint" "launch" {
  portfolio_id = aws_servicecatalog_portfolio.main.id
  product_id   = aws_servicecatalog_product.s3_bucket.id
  type         = "LAUNCH"

  parameters = jsonencode({
    RoleArn = aws_iam_role.launch.arn
  })
}

# Tag Options
resource "aws_servicecatalog_tag_option" "environment" {
  for_each = toset(["dev", "staging", "prod"])
  key      = "Environment"
  value    = each.value
}

resource "aws_servicecatalog_tag_option_resource_association" "environment" {
  for_each      = aws_servicecatalog_tag_option.environment
  resource_id   = aws_servicecatalog_portfolio.main.id
  tag_option_id = each.value.id
}

# Product: Secure S3 Bucket
resource "aws_servicecatalog_product" "s3_bucket" {
  name  = "Secure-S3-Bucket"
  owner = "Platform Team"
  type  = "CLOUD_FORMATION_TEMPLATE"

  provisioning_artifact_parameters {
    name         = "v1.0"
    description  = "Initial version"
    type         = "CLOUD_FORMATION_TEMPLATE"
    template_url = "https://s3.amazonaws.com/${aws_s3_bucket.templates.id}/secure-s3-bucket.yaml"
  }
}

resource "aws_servicecatalog_product_portfolio_association" "s3" {
  portfolio_id = aws_servicecatalog_portfolio.main.id
  product_id   = aws_servicecatalog_product.s3_bucket.id
}

# S3 bucket for templates
resource "aws_s3_bucket" "templates" {
  bucket        = "sc-templates-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_object" "s3_template" {
  bucket = aws_s3_bucket.templates.id
  key    = "secure-s3-bucket.yaml"
  content = yamlencode({
    AWSTemplateFormatVersion = "2010-09-09"
    Description              = "Secure S3 bucket with encryption and versioning"
    
    Parameters = {
      BucketName = {
        Type        = "String"
        Description = "Name of the S3 bucket"
      }
      Environment = {
        Type          = "String"
        AllowedValues = ["dev", "staging", "prod"]
        Default       = "dev"
      }
    }

    Resources = {
      Bucket = {
        Type = "AWS::S3::Bucket"
        Properties = {
          BucketName = { Ref = "BucketName" }
          BucketEncryption = {
            ServerSideEncryptionConfiguration = [{
              ServerSideEncryptionByDefault = {
                SSEAlgorithm = "AES256"
              }
            }]
          }
          VersioningConfiguration = {
            Status = "Enabled"
          }
          PublicAccessBlockConfiguration = {
            BlockPublicAcls       = true
            BlockPublicPolicy     = true
            IgnorePublicAcls      = true
            RestrictPublicBuckets = true
          }
          Tags = [{
            Key   = "Environment"
            Value = { Ref = "Environment" }
          }]
        }
      }
    }

    Outputs = {
      BucketArn = {
        Value       = { "Fn::GetAtt" = ["Bucket", "Arn"] }
        Description = "ARN of the created bucket"
      }
    }
  })
}

# Principal association (allow IAM users/roles to use portfolio)
# Note: The developer_role must exist in your account before applying
resource "aws_servicecatalog_principal_portfolio_association" "developers" {
  portfolio_id  = aws_servicecatalog_portfolio.main.id
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.developer_role}"
}



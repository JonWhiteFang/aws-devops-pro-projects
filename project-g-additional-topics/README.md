# Project G: Additional Exam Topics

Contains additional implementations for exam topics not covered in Projects A-F.

## Contents

### 1. EC2 Image Builder (AMI Pipeline)
**Path:** `image-builder/`

Automated AMI creation pipeline with:
- Base Amazon Linux 2023 image
- Security hardening components
- Application pre-installation
- Automated testing
- Cross-region distribution

### 2. Lambda Deployment with SAM
**Path:** `lambda-sam/`

Serverless CI/CD with:
- SAM template
- CodePipeline integration
- Canary deployments
- Rollback on errors

### 3. Service Catalog Portfolio
**Path:** `service-catalog/`

Self-service provisioning with:
- Product portfolio
- Launch constraints
- TagOptions
- Provisioned product constraints

## Deployment

Each subdirectory has its own deployment instructions.

```bash
cd image-builder
terraform init
terraform apply
```

## Exam Relevance

- EC2 Image Builder: AMI lifecycle, golden images
- SAM/Lambda deployments: Serverless CI/CD patterns
- Service Catalog: Self-service, governance

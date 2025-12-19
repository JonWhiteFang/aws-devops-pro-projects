# AWS DevOps Pro Projects — Overview

This repository contains seven hands-on projects aligned to the AWS Certified DevOps Engineer – Professional exam domains.

**Last Updated:** 2025-12-19

---

## Project A: CI/CD with ECS Blue/Green Deployments
**Path:** `project-a-cicd-ecs-bluegreen/`

**Purpose:** Demonstrates a complete CI/CD pipeline deploying a containerised Node.js application to ECS Fargate with CodeDeploy blue/green deployments.

**Key Components:**
- **Application:** Express.js server with `/health` and `/` endpoints
- **Infrastructure (Terraform):**
  - VPC with public subnets
  - ECS Fargate cluster with Container Insights enabled
  - Application Load Balancer with blue/green target groups
  - ECR repository with lifecycle policy (keeps last 10 images)
  - CodeCommit repository (source)
  - CodeBuild projects (build & integration test)
  - CodePipeline with Source → Build → Approval → Deploy → Test stages
  - CodeDeploy application with ECS deployment group (blue/green, auto-rollback)
  - SNS notifications for pipeline events
  - Secrets Manager for application secrets
  - Scoped IAM policies (least privilege)

**Exam Relevance:** SDLC Automation, CI/CD pipelines, deployment strategies, rollback mechanisms, approval gates.

---

## Project B: IaC & Config Remediation
**Path:** `project-b-iac-config-remediation/`

**Purpose:** Implements AWS Config rules (managed and custom) with automated remediation via SSM Automation.

**Key Components:**
- **AWS Config:** Recorder, delivery channel, S3 bucket for logs
- **Managed Rules:**
  - `S3_BUCKET_PUBLIC_READ_PROHIBITED`
  - `ENCRYPTED_VOLUMES`
  - `RDS_STORAGE_ENCRYPTED`
- **Custom Rule:** Lambda function checking for required tags (`Owner`, `Environment`)
- **Remediation:** `aws_config_remediation_configuration` linked to SSM Automation document
- **SSM Automation:** Auto-tags non-compliant EC2 instances
- **Lambda Permission:** Proper Config-to-Lambda invocation permission

**Exam Relevance:** Configuration management, compliance as code, automated remediation, custom Config rules.

---

## Project C: Multi-Region with Route 53 & DynamoDB Global Tables
**Path:** `project-c-multiregion-route53-dynamodb/`

**Purpose:** Sets up multi-region active-passive architecture with DNS failover and globally replicated data.

**Key Components:**
- **VPC Infrastructure:** Complete networking in both regions (eu-west-1, eu-west-2)
- **Lambda Functions:** Sample application behind ALBs in each region
- **Application Load Balancers:** Properly configured with subnets and security groups
- **DynamoDB Global Table:** Replicated across two regions
- **Route 53:**
  - Health checks against ALBs in each region
  - Failover routing policy (primary/secondary)
  - Latency-based routing example (alternative)
  - Alias records pointing to regional ALBs
- **AWS Backup:** Cross-region backup with daily and weekly schedules

**Exam Relevance:** High availability, disaster recovery, multi-region architectures, DNS failover, latency routing, backup strategies.

---

## Project D: Observability with CloudWatch
**Path:** `project-d-observability-cloudwatch/`

**Purpose:** Creates CloudWatch dashboards, metric alarms, and demonstrates custom metrics publishing via Embedded Metric Format (EMF).

**Key Components:**
- **CloudWatch Dashboard:** Widgets for ALB 5xx, ECS CPU/Memory, custom metrics, request count & P99 latency
- **SNS Topic:** Alert notifications
- **Metric Alarms:**
  - ALB 5xx threshold alarm
  - ECS CPU utilisation alarm
  - Composite alarm (5xx AND CPU)
  - Anomaly detection alarm for request count
- **Log Metric Filters:** Error count and latency extraction
- **Logs Insights Queries:** Comprehensive query examples in `logs_insights_queries.md`
- **X-Ray:** Sampling rules and trace groups
- **CloudWatch Synthetics:** Canary for endpoint monitoring
- **Python Script:** Example EMF publisher for custom application metrics

**Exam Relevance:** Monitoring, logging, custom metrics, alerting, composite alarms, anomaly detection, distributed tracing.

---

## Project E: Incident Response with SSM Automation
**Path:** `project-e-incident-response-ssm/`

**Purpose:** Automates incident response by triggering SSM Automation runbooks from CloudWatch alarm state changes.

**Key Components:**
- **SSM Automation Documents:**
  - `RestartEcsService` — forces new ECS deployment
  - `RecoverEC2Instance` — stops and starts EC2 instance
  - `CreateSnapshotBeforeAction` — creates EBS snapshot before remediation
- **EventBridge Rules:**
  - Alarm-to-ECS-restart trigger
  - Alarm-to-OpsItem creation for non-critical alerts
- **OpsCenter Integration:** Automatic OpsItem creation from warning alarms
- **Parameter Store:** Configuration for runbook parameters
- **Scoped IAM Roles:** For SSM execution and EventBridge invocation

**Exam Relevance:** Incident response automation, event-driven remediation, SSM Automation, EventBridge patterns, OpsCenter.

---

## Project F: Governance & Multi-Account
**Path:** `project-f-governance-multiaccount/`

**Purpose:** Provides Service Control Policies (SCPs) and security services for organisational governance.

**Key Components:**
- **Service Control Policies:**
  - Deny Public S3 ACLs
  - Deny Unsupported Regions
  - Require IMDSv2 for EC2
  - Deny Root User Actions
- **CloudTrail:** Organisation-wide trail to central S3 bucket
- **Security Hub:** Enabled with delegated admin account
- **GuardDuty:** Enabled with delegated admin account
- **IAM Access Analyzer:** Organisation-level analyzer
- **CloudFormation StackSets:** Deploy baseline alarms across all accounts
- **Terraform:** Full IaC for deploying all governance components

**Exam Relevance:** Multi-account governance, SCPs, preventive controls, AWS Organizations, security services, StackSets.

---

## Project G: Additional Exam Topics
**Path:** `project-g-additional-topics/`

**Purpose:** Covers additional exam topics not addressed in Projects A-F.

**Key Components:**

### EC2 Image Builder (`image-builder/`)
- Base Amazon Linux 2023 image
- Security hardening components
- Automated testing phase
- Cross-region AMI distribution
- Weekly pipeline schedule

### Lambda SAM Deployment (`lambda-sam/`)
- SAM template with canary deployment
- Pre-traffic and post-traffic hooks
- CloudWatch alarms for automatic rollback
- API Gateway integration

### Service Catalog (`service-catalog/`)
- Portfolio with approved products
- Launch constraints with IAM role
- TagOptions for governance
- Secure S3 bucket product template

**Exam Relevance:** AMI lifecycle, golden images, serverless CI/CD, canary deployments, self-service provisioning.

---

## Technology Stack Summary

| Technology | Usage |
|------------|-------|
| Terraform | All infrastructure provisioning |
| AWS CodePipeline/CodeBuild/CodeDeploy | CI/CD orchestration |
| ECS Fargate | Container workloads |
| AWS Config | Compliance monitoring |
| Lambda (Python) | Custom Config rule, multi-region app, SAM |
| SSM Automation | Remediation & incident response |
| Route 53 | DNS failover & latency routing |
| DynamoDB Global Tables | Multi-region data |
| CloudWatch | Dashboards, alarms, metrics, Logs Insights |
| EventBridge | Event-driven automation |
| SCPs | Organisational guardrails |
| Security Hub | Security findings aggregation |
| GuardDuty | Threat detection |
| IAM Access Analyzer | External access detection |
| OpsCenter | Operational issue tracking |
| X-Ray | Distributed tracing |
| Synthetics | Canary monitoring |
| EC2 Image Builder | AMI pipelines |
| SAM | Serverless deployments |
| Service Catalog | Self-service provisioning |
| AWS Backup | Cross-region data protection |
| StackSets | Multi-account deployments |

---

## Repository Features

| Feature | Description |
|---------|-------------|
| Per-project READMEs | Prerequisites, deployment, variables, cleanup, costs |
| Backend configuration | Shared S3 backend via `backend.hcl` |
| Example tfvars | `terraform.tfvars.example` in each project |
| Outputs | Resource ARNs, URLs, connection info |
| Pre-commit hooks | terraform fmt, validate, tflint, checkov |
| GitHub Actions | CI/CD validation workflow |
| Scoped IAM | Least-privilege policies throughout |
| Architecture diagrams | Mermaid diagrams in `docs/` |
| Exam mapping | Question topics mapped to projects |

---

## Exam Domain Mapping

| Project | Primary Exam Domain |
|---------|---------------------|
| A | Domain 1: SDLC Automation |
| B | Domain 2: Configuration Management & IaC |
| C | Domain 5: High Availability, Fault Tolerance, DR |
| D | Domain 3: Monitoring & Logging |
| E | Domain 4: Incident & Event Response |
| F | Domain 6: Policies & Standards Automation |
| G | Domains 1, 2, 6 (Additional Topics) |

---

## Quick Start

```bash
# One-time setup: configure your backend
cp backend.hcl.example backend.hcl
# Edit backend.hcl with your S3 bucket name

# Navigate to a project
cd project-a-cicd-ecs-bluegreen/infra-terraform

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars

# Deploy
terraform init -backend-config=../../backend.hcl
terraform plan
terraform apply

# Cleanup
terraform destroy
```

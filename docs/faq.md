# Frequently Asked Questions

## General

### Q: Do I need to deploy all projects?

No. Each project is self-contained and can be deployed independently. However, deploying them in order (A → G) provides a logical learning progression as concepts build on each other.

### Q: Which AWS region should I use?

The default is `eu-west-1` (Ireland). You can change this in `terraform.tfvars` for any project. Some projects (like C) use multiple regions by design.

### Q: How much will this cost?

Running all projects simultaneously costs approximately $100-150/month. Individual projects range from $1-50/month. See [docs/cost-management.md](cost-management.md) for detailed breakdowns and optimization strategies.

### Q: Can I use this for production?

These projects demonstrate exam-relevant patterns but are optimized for learning. For production use, you should:
- Enable encryption at rest for all storage
- Implement proper network segmentation (private subnets)
- Add WAF to ALBs
- Enable VPC Flow Logs
- Review and tighten IAM policies
- Add proper tagging strategy
- Implement backup retention policies

---

## Setup Issues

### Q: Terraform init fails with "backend configuration required"

You need to configure the shared backend:

```bash
cp backend.hcl.example backend.hcl
# Edit backend.hcl with your S3 bucket name
terraform init -backend-config=../../backend.hcl
```

### Q: "Error: No valid credential sources found"

Your AWS credentials aren't configured:

```bash
aws configure
# Or set environment variables:
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx
export AWS_DEFAULT_REGION=eu-west-1
```

### Q: "Error: creating S3 Bucket: BucketAlreadyExists"

S3 bucket names are globally unique. Edit `terraform.tfvars` to use a unique bucket name, or let Terraform generate one using `random_id`.

### Q: Pre-commit hooks fail

Install the required tools:

```bash
pip install pre-commit
pre-commit install

# For tflint
brew install tflint  # macOS
# or download from GitHub releases

# For checkov
pip install checkov
```

---

## Project-Specific Questions

### Project A: CI/CD

**Q: CodePipeline is stuck at approval stage**

This is expected. Navigate to CodePipeline in the AWS Console and click "Review" then "Approve" to continue.

**Q: ECS tasks keep failing**

Check CloudWatch Logs for the ECS service. Common issues:
- Container image not found in ECR
- Task role missing permissions
- Health check failing (check ALB target group health)

### Project B: Config

**Q: Config rules show "No results" for compliance**

Config rules evaluate resources when they change. To force evaluation:

```bash
aws configservice start-config-rules-evaluation --config-rule-names required-tags
```

**Q: Remediation isn't running automatically**

Check that:
1. `automatic = true` is set in the remediation configuration
2. The SSM Automation role has correct permissions
3. The resource is actually non-compliant

### Project C: Multi-Region

**Q: Route 53 records aren't created**

Route 53 requires a hosted zone. If you don't have one, the core infrastructure still deploys — Route 53 is optional.

**Q: DynamoDB Global Table replication is slow**

Global Tables use asynchronous replication. Writes in one region typically appear in others within 1-2 seconds, but this isn't guaranteed.

### Project D: Observability

**Q: Dashboard shows "No data available"**

Metrics need time to populate. Also verify:
- The referenced resources (ALB, ECS) exist
- The metric namespace and dimensions are correct
- You're viewing the correct time range

**Q: Synthetics canary fails immediately**

Check that the target URL is accessible. The canary runs from AWS-managed infrastructure, so your endpoint must be publicly accessible or in a VPC with proper routing.

### Project E: Incident Response

**Q: EventBridge rule isn't triggering**

Verify:
1. The CloudWatch alarm is actually changing state
2. The event pattern matches the alarm name
3. The target role has permission to invoke SSM

**Q: SSM Automation fails with access denied**

The automation assume role needs permissions for the actions it performs. Check the IAM policy attached to the SSM role.

### Project F: Governance

**Q: Security Hub shows no findings**

Security Hub needs time to aggregate findings. Initial population can take 24-48 hours. Also ensure GuardDuty and other integrations are enabled.

**Q: SCPs aren't working**

SCPs only work with AWS Organizations. The policy files in this project are examples for study — deploying them requires an organization structure.

### Project G: Additional Topics

**Q: Image Builder pipeline never completes**

Image Builder pipelines can take 30-60 minutes. Check:
- The build instance can reach the internet (for package updates)
- The instance profile has required permissions
- CloudWatch Logs for the build (`/aws/imagebuilder/`)

**Q: Service Catalog product launch fails**

Verify:
- The launch constraint role exists and has correct permissions
- The CloudFormation template is valid
- The user has permission to use the portfolio

---

## Exam Preparation

### Q: Which projects are most important for the exam?

All domains are tested, but focus on:
- **Project A** (22% of exam) — CI/CD is heavily tested
- **Project C** (18% of exam) — Multi-region and DR scenarios are common
- **Project B & F** (17% + 13%) — Config and governance appear frequently

### Q: Should I memorize the Terraform code?

No. The exam tests AWS concepts, not Terraform syntax. Use these projects to understand:
- How services integrate
- When to use each service
- Trade-offs between approaches
- Troubleshooting patterns

### Q: Are there practice questions?

See [docs/exam-question-mapping.md](exam-question-mapping.md) for sample scenarios mapped to each project.

---

## Cleanup

### Q: Terraform destroy fails with "resource still in use"

Some resources have dependencies that must be removed first:
- Empty S3 buckets before deletion
- Scale ECS services to 0
- Delete CloudWatch log groups manually if needed

```bash
# Force delete non-empty S3 bucket
aws s3 rb s3://bucket-name --force
```

### Q: Resources remain after destroy

Check for:
- Resources created outside Terraform
- Resources in other regions
- CloudWatch Log Groups (often retained)
- S3 buckets with versioning (delete all versions)

```bash
# Find remaining resources
aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=devops-pro
```

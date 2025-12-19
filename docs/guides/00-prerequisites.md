# Prerequisites & Environment Setup

Complete these steps before starting any project.

---

## Required Tools

### 1. Terraform >= 1.5.0

```bash
# macOS
brew install terraform

# Linux (Ubuntu/Debian)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verify
terraform version
```

### 2. AWS CLI (>= 2.0)

```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify
aws --version
```

### 3. AWS SAM CLI (for Project G)

```bash
# macOS
brew install aws-sam-cli

# Linux
pip install aws-sam-cli

# Verify
sam --version
```

### 4. Additional Tools

```bash
# Git
git --version

# jq (for parsing JSON outputs)
# macOS
brew install jq

# Linux
sudo apt install jq
```

---

## AWS Account Requirements

1. **AWS Account** with administrative access (or scoped permissions for each service)
2. **IAM User/Role** with programmatic access
3. **AWS CLI configured:**

```bash
aws configure
# Enter:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region: eu-west-1 (or your preferred region)
# - Default output format: json
```

4. **Verify access:**

```bash
aws sts get-caller-identity
```

---

## Required IAM Permissions

Your IAM user/role needs permissions for:

- EC2, VPC, ECS, ECR, ELB
- CodePipeline, CodeBuild, CodeDeploy, CodeCommit
- Lambda, API Gateway
- DynamoDB, S3
- Route 53, CloudWatch, SNS, EventBridge
- SSM, Config, CloudTrail
- Organizations, Security Hub, GuardDuty (Project F)
- Service Catalog, EC2 Image Builder (Project G)
- IAM (create roles and policies)

**Recommended:** Use an account with `AdministratorAccess` for learning purposes.

---

## Cost Warning

⚠️ **These projects will incur AWS charges.**

| Project | Estimated Cost (if left running 24h) |
|---------|--------------------------------------|
| A | $5-10 (ECS Fargate, ALB, NAT Gateway) |
| B | $1-2 (Config rules, Lambda) |
| C | $8-15 (Multi-region ALBs, NAT Gateways) |
| D | $2-5 (CloudWatch, Synthetics) |
| E | $1-2 (EventBridge, SSM) |
| F | $2-5 (CloudTrail, Security Hub) |
| G | $3-8 (Image Builder, Service Catalog) |

**Total if all running simultaneously:** $20-50/day

**Recommendation:** Deploy one project at a time and destroy before moving to the next.

---

## Environment Setup

### Step 1: Clone the Repository

```bash
cd ~/projects  # or your preferred directory
git clone <repository-url> aws-devops-pro-projects
cd aws-devops-pro-projects
```

### Step 2: Set Environment Variables

```bash
cat > ~/.devops-pro-env << 'EOF'
export AWS_DEFAULT_REGION="eu-west-1"
export AWS_REGION="eu-west-1"
export TF_VAR_aws_region="eu-west-1"
export TF_VAR_environment="dev"
export TF_VAR_project_name="devops-pro"
EOF

source ~/.devops-pro-env
```

### Step 3: Verify AWS Connectivity

```bash
# Check identity
aws sts get-caller-identity

# Check region
aws configure get region

# Test basic permissions
aws ec2 describe-vpcs --max-items 1
```

### Step 4: Configure Remote State Backend

All projects use a shared S3 backend configuration. Set this up once:

```bash
# Create S3 bucket for state
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 mb s3://devops-pro-tfstate-${ACCOUNT_ID}

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket devops-pro-tfstate-${ACCOUNT_ID} \
  --versioning-configuration Status=Enabled
```

Then configure the shared backend file:

```bash
# Copy the template
cp backend.hcl.example backend.hcl

# Edit with your bucket name
# bucket = "devops-pro-tfstate-YOUR_ACCOUNT_ID"
```

When initializing any project, use:

```bash
terraform init -backend-config=../../backend.hcl
```

---

## Next Step

Proceed to [01-project-a-cicd-ecs.md](01-project-a-cicd-ecs.md)

# Project G: Additional Topics

**Exam Domains:** Domains 1, 2, 6 (Additional Topics)
**Time:** 45-60 minutes setup, 30-45 minutes validation

---

## Overview

Deploy additional exam topics:
- EC2 Image Builder for golden AMI pipelines
- Lambda SAM deployment with canary releases
- Service Catalog for self-service provisioning

---

## Part 1: EC2 Image Builder

### Navigate to Directory

```bash
cd ~/aws-devops-pro-projects/project-g-additional-topics/image-builder
```

### Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

```hcl
aws_region   = "eu-west-1"
environment  = "dev"
project_name = "devops-pro-g"

base_ami_id          = "ami-0c38b837cd80f13bb"  # Update for your region
distribution_regions = ["eu-west-1", "eu-west-2"]
build_instance_type  = "t3.medium"
```

### Deploy

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Validate

```bash
aws imagebuilder list-image-pipelines | jq '.imagePipelineList[] | {name: .name, status: .status}'
aws imagebuilder list-image-recipes | jq '.imageRecipeSummaryList[] | {name: .name, platform: .platform}'
aws imagebuilder list-components --owner Self | jq '.componentVersionList[] | {name: .name, version: .version}'
```

### Trigger Pipeline

```bash
PIPELINE_ARN=$(terraform output -raw pipeline_arn)
aws imagebuilder start-image-pipeline-execution --image-pipeline-arn $PIPELINE_ARN

# Check status (building takes 20-40 minutes)
aws imagebuilder list-image-pipeline-images --image-pipeline-arn $PIPELINE_ARN | jq '.imageSummaryList[] | {name: .name, state: .state.status}'
```

### Check Built AMIs

```bash
aws ec2 describe-images --owners self --filters "Name=tag:CreatedBy,Values=EC2 Image Builder" | jq '.Images[] | {imageId: .ImageId, name: .Name, state: .State}'
```

---

## Part 2: Lambda SAM Deployment

### Navigate to Directory

```bash
cd ~/aws-devops-pro-projects/project-g-additional-topics/lambda-sam
```

### Build the Application

```bash
sam build
```

### Deploy with Canary Configuration

```bash
sam deploy --guided
```

**Guided prompts:**
- Stack Name: `devops-pro-g-lambda`
- AWS Region: `eu-west-1`
- Confirm changes before deploy: `Y`
- Allow SAM CLI IAM role creation: `Y`
- Save arguments to samconfig.toml: `Y`

### Validate

```bash
API_ENDPOINT=$(aws cloudformation describe-stacks --stack-name devops-pro-g-lambda --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' --output text)
curl -s $API_ENDPOINT | jq .
```

### Test Canary Deployment

```bash
# Edit src/app.py to change the response
nano src/app.py

# Rebuild and deploy
sam build
sam deploy

# Watch canary deployment
watch -n 5 "aws codedeploy list-deployments --application-name ServerlessDeploymentApplication --query 'deployments[0]' --output text | xargs -I {} aws codedeploy get-deployment --deployment-id {} | jq '.deploymentInfo | {status, deploymentOverview}'"
```

### Verify Traffic Shifting

```bash
FUNCTION_NAME=$(aws cloudformation describe-stack-resources --stack-name devops-pro-g-lambda --query 'StackResources[?ResourceType==`AWS::Lambda::Function`].PhysicalResourceId' --output text)
aws lambda list-aliases --function-name $FUNCTION_NAME | jq '.Aliases[] | {name: .Name, version: .FunctionVersion, routingConfig: .RoutingConfig}'
```

---

## Part 3: Service Catalog

### Navigate to Directory

```bash
cd ~/aws-devops-pro-projects/project-g-additional-topics/service-catalog
```

### Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

```hcl
aws_region   = "eu-west-1"
environment  = "dev"
project_name = "devops-pro-g"

portfolio_principals = [
  "arn:aws:iam::123456789012:role/DeveloperRole"
]
```

### Deploy

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Validate

```bash
aws servicecatalog list-portfolios | jq '.PortfolioDetails[] | {id: .Id, name: .DisplayName}'

PORTFOLIO_ID=$(terraform output -raw portfolio_id)
aws servicecatalog search-products-as-admin --portfolio-id $PORTFOLIO_ID | jq '.ProductViewDetails[] | {name: .ProductViewSummary.Name, type: .ProductViewSummary.Type}'
```

### Launch a Product

```bash
PRODUCT_ID=$(aws servicecatalog search-products-as-admin --portfolio-id $PORTFOLIO_ID --query 'ProductViewDetails[0].ProductViewSummary.ProductId' --output text)
ARTIFACT_ID=$(aws servicecatalog list-provisioning-artifacts --product-id $PRODUCT_ID --query 'ProvisioningArtifactDetails[0].Id' --output text)

aws servicecatalog provision-product \
  --product-id $PRODUCT_ID \
  --provisioning-artifact-id $ARTIFACT_ID \
  --provisioned-product-name "test-s3-bucket" \
  --provisioning-parameters Key=BucketName,Value=test-bucket-$(date +%s)
```

### Check Provisioned Products

```bash
aws servicecatalog scan-provisioned-products | jq '.ProvisionedProducts[] | {name: .Name, status: .Status, type: .Type}'
```

---

## Teardown

### Service Catalog

```bash
for PP in $(aws servicecatalog scan-provisioned-products --query 'ProvisionedProducts[*].Id' --output text); do
  aws servicecatalog terminate-provisioned-product --provisioned-product-id $PP
done
sleep 30

cd ~/aws-devops-pro-projects/project-g-additional-topics/service-catalog
terraform destroy
```

### Lambda SAM

```bash
cd ~/aws-devops-pro-projects/project-g-additional-topics/lambda-sam
sam delete --stack-name devops-pro-g-lambda --no-prompts
```

### Image Builder

```bash
# Cancel running builds
PIPELINE_ARN=$(terraform output -raw pipeline_arn)
for IMAGE in $(aws imagebuilder list-image-pipeline-images --image-pipeline-arn $PIPELINE_ARN --query 'imageSummaryList[?state.status==`BUILDING`].arn' --output text); do
  aws imagebuilder cancel-image-creation --image-build-version-arn $IMAGE
done

cd ~/aws-devops-pro-projects/project-g-additional-topics/image-builder
terraform destroy
```

### Manual Cleanup

```bash
# Delete AMIs
for AMI in $(aws ec2 describe-images --owners self --filters "Name=tag:CreatedBy,Values=EC2 Image Builder" --query 'Images[*].ImageId' --output text); do
  aws ec2 deregister-image --image-id $AMI
done

# Delete snapshots
for SNAP in $(aws ec2 describe-snapshots --owner-ids self --filters "Name=tag:CreatedBy,Values=EC2 Image Builder" --query 'Snapshots[*].SnapshotId' --output text); do
  aws ec2 delete-snapshot --snapshot-id $SNAP
done
```

---

## Key Exam Concepts Covered

- ✅ EC2 Image Builder pipelines
- ✅ Image recipes and components
- ✅ AMI distribution across regions
- ✅ SAM deployment model
- ✅ Lambda canary deployments
- ✅ Pre/post traffic hooks
- ✅ Service Catalog portfolios and products
- ✅ Launch constraints
- ✅ Self-service provisioning

---

## Next Step

Proceed to [08-teardown.md](08-teardown.md)

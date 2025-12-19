terraform {
  backend "s3" {
    # Bucket, region, and settings provided via -backend-config=../../backend.hcl
    key = "project-g-image-builder/terraform.tfstate"
  }
}

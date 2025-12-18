terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias  = "a"
  region = var.region_a
}

provider "aws" {
  alias  = "b"
  region = var.region_b
}

# Default provider for Route 53 (global service)
provider "aws" {
  region = var.region_a
}

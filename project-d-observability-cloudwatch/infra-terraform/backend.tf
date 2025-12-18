terraform {
  backend "s3" {
    bucket       = "devops-pro-tfstate-615154569038"
    key          = "project-d-observability/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
    encrypt      = true
  }
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-west-1"
}

variable "distribution_regions" {
  description = "List of regions to distribute the AMI to"
  type        = list(string)
  default     = ["eu-west-1", "eu-west-2"]
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-west-1"
}

variable "developer_role" {
  description = "IAM role name that can access the Service Catalog portfolio"
  type        = string
  default     = "DeveloperRole"
}

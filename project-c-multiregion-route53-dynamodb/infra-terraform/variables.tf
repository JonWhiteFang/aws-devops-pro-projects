variable "region_a" {
  type        = string
  default     = "eu-west-1"
  description = "Primary region"
}

variable "region_b" {
  type        = string
  default     = "eu-west-2"
  description = "Secondary region"
}

variable "domain_name" {
  type        = string
  default     = ""
  description = "Route 53 hosted zone domain name (optional)"
}

variable "enable_route53" {
  type        = bool
  default     = false
  description = "Enable Route 53 DNS configuration (requires domain_name)"
}

variable "project" {
  type    = string
  default = "multiregion-app"
}

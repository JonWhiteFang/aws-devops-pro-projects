variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "alb_name" {
  type        = string
  description = "ALB name for CloudWatch metrics (e.g., app/my-alb/1234567890)"
}

variable "ecs_cluster" {
  type        = string
  description = "ECS cluster name"
}

variable "ecs_service" {
  type        = string
  description = "ECS service name"
}

variable "log_group_name" {
  type        = string
  default     = "/ecs/demo-api"
  description = "CloudWatch Log Group name"
}

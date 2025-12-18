variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "ecs_cluster" {
  type        = string
  description = "ECS cluster name for restart runbook"
}

variable "ecs_service" {
  type        = string
  description = "ECS service name for restart runbook"
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "project" {
  type    = string
  default = "demo-ecs-bluegreen"
}

variable "app_port" {
  type    = number
  default = 8080
  description = "Application port - must match the port in app/server.js and app/taskdef.json"
}

variable "app-name" {
  type = string
}

variable "lambda-description" {
  type = string
}

variable "path-to-jar" {
  type = string
}

variable "handler" {
  type = string
}

variable "runtime" {
  type = string
}

variable "memory" {
  type = string
}

variable "timeout" {
  type = string
}

variable "dns-name" {
  type = string
}

variable "api-description" {
  type = string
}

variable "env" {
  type = string
}

variable "account-id" {
  type = string
}

variable "method-paths" {
  type = list
}

variable "root-resource" {
  default = false
}

variable "root-resource-method" {
  type = string
  default = ""
}

variable "root-resource-request-params" {
  type = map
  default = {}
}

variable "resource-request-params" {
  type = map
  default = {}
}

data "aws_ssm_parameter" "us-east-1-cert" {
  name = "/acs/acm/us-east-1/zone-cert-arn"
}
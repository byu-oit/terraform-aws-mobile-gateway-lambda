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

variable "methods" {
  type = list(object({
    path = string
    type = string
  }))
  default = []
}

variable "root-resource" {
  default = false
}

variable "root-resource-method" {
  type = string
  default = ""
}

variable "root-resource-request-params" {
  type = map(string)
  default = {}
}

variable "resource-request-params" {
  type = map(string)
  default = {}
}

variable "lambda-environment-variables" {
  type = map(string)
  default = {}
}

variable "resource-authorization" {
  type = string
  default = "NONE"
}

variable "root-resource-authorization" {
  type = string
  default = "NONE"
}

variable "swagger-path" {
  type = string
}

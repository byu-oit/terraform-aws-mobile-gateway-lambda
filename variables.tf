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
  type = list
}

variable "api-description" {
  type = string
}

variable "env" {
  type = string
}
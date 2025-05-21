########################################################
### config
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

########################################################
### vars
variable "ALB_from_IP" {
  type = string
}

########################################################
### import
variable "vpc_id" {
  type = string
}


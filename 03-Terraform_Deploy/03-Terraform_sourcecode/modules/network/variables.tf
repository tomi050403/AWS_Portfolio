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
variable "vpc_cidr_block" {
  type = string
}

variable "AZ_1" {
  type = string
}

variable "AZ_1_publicsub" {
  type = string
}

variable "AZ_1_privatesub" {
  type = string
}

variable "AZ_2" {
  type = string
}

variable "AZ_2_publicsub" {
  type = string
}

variable "AZ_2_privatesub" {
  type = string
}

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
### import
variable "web_sg_id" {
  type = string
}

variable "alb_sg_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_1a" {
  type = string
}

variable "public_subnet_1c" {
  type = string
}

variable "private_subnet_1a" {
  type = string
}

variable "private_subnet_1c" {
  type = string
}

variable "web_server_id" {
  type = string
}

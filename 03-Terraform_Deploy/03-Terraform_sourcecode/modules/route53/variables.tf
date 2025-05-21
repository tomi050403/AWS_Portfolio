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
variable "private_host_zone" {
  type = string
}


########################################################
### import
variable "vpc_id" {
  type = string
}

variable "appsv_instance_private_ip" {
  type = string
}

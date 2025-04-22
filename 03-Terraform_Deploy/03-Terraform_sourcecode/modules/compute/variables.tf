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
variable "appsv_instance_type" {
  type = string
}

variable "app_sv_ami" {
  type = string
}

variable "websv_instance_type" {
  type = string
}

variable "web_sv_ami" {
  type = string
}


########################################################
### import
variable "public_subnet_1a" {
  type = string
}

variable "private_subnet_1a" {
  type = string
}

variable "app_sg_id" {
  type = string
}

variable "web_sg_id" {
  type = string
}

variable "ec2_profile_name" {
  type = string
}
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
variable "rds_username" {
  type = string
}

variable "rds_instance_class" {
  type = string
}

variable "rds_az_none_multiaz" {
  type = string
}

variable "rds_sg_id" {
  type = string
}

variable "rds_db_name" {
  type = string
}

########################################################
### import
variable "private_subnet_1a" {
  type = string
}

variable "private_subnet_1c" {
  type = string
}


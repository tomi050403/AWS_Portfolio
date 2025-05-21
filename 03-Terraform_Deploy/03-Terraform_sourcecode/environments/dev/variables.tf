########################################################
### network
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


########################################################
### Security
variable "ALB_from_IP" {
  type = string
}

########################################################
### compute
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
### rds
variable "rds_username" {
  type = string
}

variable "rds_instance_class" {
  type = string
}

variable "rds_az_none_multiaz" {
  type = string
}

variable "rds_db_name" {
  type = string
}

########################################################
### route53
variable "private_host_zone" {
  type = string
}

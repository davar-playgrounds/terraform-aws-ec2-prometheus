variable "aws_region" {
  description = "AWS region to launch servers. For NY,BOS,VA use us-east-1. For SF use us-west-2"
  default     = "us-east-1"
}



variable "fellow_name" {
  description = "Haitham Ghalwash"
}

variable "cidr"{  }

data "aws_availability_zones" "available" {
    state = "available"
}

######
# Data
######
variable "keypair_name" {
  description = "Haitham-IAM-keypair"
}
variable "amis" {
 type = map (string)
  default = {
    "us-east-1" = "ami-0b6b1f8f449568786"
  }
}
variable "cluster_name" {
  description = "Prometheus cluster"
  default     = "Prometheus"
}
variable "root_volume_size" {
  description = "Root volume size"
  type        = string
  default     = 100
}
variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "m4.large"
  #"t2.small"
}
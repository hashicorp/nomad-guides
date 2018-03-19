variable "region" {
  default     = "us-east-1"
  description = "AWS Region"
}

variable "platform" {
  default     = "rhel"
  description = "The OS Platform"
}

variable "user" {
  default = "ec2-user"
}

variable "demoami" {
  default = "ami-26ebbc5c"
}

variable "store_name" {
  default = "&#128640; Spacely Space Sprockets &#128640;"
}

variable "key_name" {
  description = "SSH key name in your AWS account for AWS instances."
  default = "scarolan"
}

variable "private_key_file" {
  description = "SSH key file for connections"
  default = "~/.ssh/id_dsa"
}

variable "ecommerce_servers" {
  default     = "3"
  description = "The number of demo ecommerce servers to launch."
}

variable "nomad_servers" {
  default     = "1"
  description = "The number of nomad servers to launch."
}

variable "ecommerce_instance_type" {
  default     = "t2.medium"
  description = "AWS Instance type, if you change, make sure it is compatible with AMI, not all AMIs allow all instance types "
}

variable "nomad_instance_type" {
  default     = "t2.medium"
  description = "AWS Instance type, if you change, make sure it is compatible with AMI, not all AMIs allow all instance types "
}

variable "ecomTagName" {
  default     = "ecommerce"
  description = "Name tag for the ecommerce servers"
}

variable "subnets" {
  type = "map"
  description = "map of subnets to deploy your infrastructure in, must have as many keys as your server count (default 3), -var 'subnets={\"0\"=\"subnet-12345\",\"1\"=\"subnets-23456\"}' "
  default = {
    "0" = "subnet-e3eecfbe",
    "1" = "subnet-fc6550a1",
    "2" = "subnet-ca818dae"
  }
}

variable "vpc_id" {
  type = "string"
  description = "ID of the VPC to use - in case your account doesn't have default VPC"
  default = "vpc-63832918"
}

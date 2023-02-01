# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
  description = "The AWS region to deploy to."
  default     = "us-east-1"
}

variable "ami" {
  description = "AMI ID"
  default = "ami-06f5d536610fcbd6c"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  default = "10.0.1.0/24"
}

variable "subnet_az" {
  description = "The AZ for the public subnet"
  default = "us-east-1a"
}

variable "server_instance_type" {
  description = "The AWS instance type to use for servers."
  default     = "t2.medium"
}

variable "client_instance_type" {
  description = "The AWS instance type to use for clients."
  default     = "t2.medium"
}

variable "key_name" {}

variable "private_key_data" {
  description = "contents of the private key"
}

variable "server_count" {
  description = "The number of servers to provision."
  default     = "1"
}

variable "client_count" {
  description = "The number of clients to provision."
  default     = "3"
}

variable "name_tag_prefix" {
  description = "prefixed to Name tag added to EC2 instances and other AWS resources"
  default     = "nomad-multi_job_demo"
}

variable "cluster_tag_value" {
  description = "Used by Consul to automatically form a cluster."
  default     = "nomad-multi_job_demo"
}

variable "owner" {
  description = "Adds owner tag to EC2 instances"
  default = ""
}

variable "ttl" {
  description = "Adds TTL tag to EC2 instances for reaping purposes. Reaping is only done for instances deployed by HashiCorp SEs. In any case, -1 means no reaping."
  default = "24"
}

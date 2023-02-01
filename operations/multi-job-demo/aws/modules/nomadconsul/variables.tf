# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {}
variable "ami" {}
variable "server_instance_type" {}
variable "client_instance_type" {}
variable "key_name" {}
variable "server_count" {}
variable "client_count" {}
variable "name_tag_prefix" {}
variable "cluster_tag_value" {}
variable "owner" {}
variable "ttl" {}
variable "vpc_id" {}
variable "subnet_id" {}
variable "private_key_data" {}
variable "route_table_association_id" {}

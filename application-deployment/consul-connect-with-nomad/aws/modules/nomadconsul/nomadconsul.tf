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

# Security Group
resource "aws_security_group" "primary" {
  name   = "${var.name_tag_prefix}-sg"
  vpc_id = "${var.vpc_id}"

  tags={
    Name = "${var.name_tag_prefix}-sg"
  }
}

# Security Group Rules
resource "aws_security_group_rule" "ssh" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "nomad_http_ingress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "ingress"
    from_port = 4646
    to_port = 4646
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "nomad_rpc_serf_ingress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "ingress"
    from_port = 4647
    to_port = 4648
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "nomad_rpc_serf_egress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "egress"
    from_port = 4647
    to_port = 4648
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "nomad_serf_udp_ingress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "ingress"
    from_port = 4648
    to_port = 4648
    protocol = "udp"
    source_security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "nomad_serf_udp_egress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "egress"
    from_port = 4648
    to_port = 4648
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "consul_http" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "ingress"
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "consul_rpc_ingress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "ingress"
    from_port = 8300
    to_port = 8300
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "consul_rpc_egress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "egress"
    from_port = 8300
    to_port = 8300
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "consul_lan_tcp_ingress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "ingress"
    from_port = 8301
    to_port = 8302
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "consul_lan_tcp_egress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "egress"
    from_port = 8301
    to_port = 8302
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "consul_lan_udp_ingress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "ingress"
    from_port = 8301
    to_port = 8302
    protocol = "udp"
    source_security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "consul_lan_udp_egress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "egress"
    from_port = 8301
    to_port = 8302
    protocol = "udp"
    source_security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "consul_dns_tcp_ingress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "ingress"
    from_port = 53
    to_port = 53
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "consul_dns_tcp_egress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "egress"
    from_port = 53
    to_port = 53
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "consul_dns_udp_ingress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "ingress"
    from_port = 53
    to_port = 53
    protocol = "udp"
    source_security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "consul_dns_udp_egress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "egress"
    from_port = 53
    to_port = 53
    protocol = "udp"
    source_security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "nomad_dynamic_ports_ingress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "ingress"
    from_port = 20000
    to_port = 32000
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "nomad_dynamic_ports_egress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "egress"
    from_port = 20000
    to_port = 32000
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "catalogue_ingress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "ingress"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "catalogue_egress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "egress"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "https_egress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "egress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "http_egress" {
    security_group_id = "${aws_security_group.primary.id}"
    type = "egress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

# Template File for Server
data "template_file" "user_data_server_primary" {
  template = "${file("${path.root}/user-data-server.sh")}"

  vars={
    server_count      = "${var.server_count}"
    region            = "${var.region}"
    cluster_tag_value = "${var.cluster_tag_value}"
  }
}

# Template File for Client
data "template_file" "user_data_client" {
  template = "${file("${path.root}/user-data-client.sh")}"

  vars={
    region            = "${var.region}"
    cluster_tag_value = "${var.cluster_tag_value}"
    server_ip = "${aws_instance.primary.0.private_ip}"
  }
}

# Server EC2 Instances
resource "aws_instance" "primary" {
  ami                    = "${var.ami}"
  instance_type          = "${var.server_instance_type}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.primary.id}"]
  subnet_id              = "${var.subnet_id}"
  count                  = "${var.server_count}"

  #Instance tags
  tags={
    Name = "${var.name_tag_prefix}-server-${count.index}"
    ConsulAutoJoin = "${var.cluster_tag_value}"
    owner = "${var.owner}"
    TTL = "${var.ttl}"
    created-by = "Terraform"
  }

  user_data            = "${data.template_file.user_data_server_primary.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.instance_profile.name}"
}

# Client EC2 Instances
resource "aws_instance" "client" {
  ami                    = "${var.ami}"
  instance_type          = "${var.client_instance_type}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.primary.id}"]
  subnet_id              = "${var.subnet_id}"
  count                  = "${var.client_count}"
  depends_on             = ["aws_instance.primary"]

  #Instance tags
  tags={
    Name = "${var.name_tag_prefix}-client-${count.index}"
    ConsulAutoJoin = "${var.cluster_tag_value}"
    owner = "${var.owner}"
    TTL = "${var.ttl}"
    created-by = "Terraform"
  }

  user_data = "${data.template_file.user_data_client.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.instance_profile.name}"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = "${var.name_tag_prefix}-profile"
  role        = "${aws_iam_role.instance_role.name}"
}

# IAM Instance Role
resource "aws_iam_role" "instance_role" {
  name_prefix        = "${var.name_tag_prefix}-role"
  assume_role_policy = "${data.aws_iam_policy_document.instance_role.json}"
}

# IAM Policy
data "aws_iam_policy_document" "instance_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM Policy
resource "aws_iam_role_policy" "auto_discover_cluster" {
  name   = "${var.name_tag_prefix}-auto-discover-cluster"
  role   = "${aws_iam_role.instance_role.id}"
  policy = "${data.aws_iam_policy_document.auto_discover_cluster.json}"
}

# IAM Policy
data "aws_iam_policy_document" "auto_discover_cluster" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "autoscaling:DescribeAutoScalingGroups",
    ]

    resources = ["*"]
  }
}

# Outputs
output "primary_server_private_ips" {
  value = ["${aws_instance.primary.*.private_ip}"]
}

output "primary_server_public_ips" {
  value = ["${aws_instance.primary.*.public_ip}"]
}

output "client_private_ips" {
  value = ["${aws_instance.client.*.private_ip}"]
}

output "client_public_ips" {
  value = ["${aws_instance.client.*.public_ip}"]
}

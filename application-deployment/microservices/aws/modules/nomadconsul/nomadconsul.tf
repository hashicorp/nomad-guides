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
variable "token_for_nomad" {}
variable "vault_url" {}
variable "vpc_id" {}
variable "subnet_id" {}

resource "aws_security_group" "primary" {
  name   = "nomad-consul-demo"
  vpc_id = "${var.vpc_id}"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ping
  ingress {
    from_port   = 8
    to_port     = 8
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Nomad TCP
  ingress {
    from_port = 4646
    to_port   = 4648
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Nomad UDP
  ingress {
    from_port = 4648
    to_port   = 4648
    protocol  = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Consul UI/HTTP
  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Consul RPC
  ingress {
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Consul Serf TCP
  ingress {
    from_port   = 8301
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Consul Serf UDP
  ingress {
    from_port   = 8301
    to_port     = 8302
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Consul DNS TCP
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Consul DNS UDP
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP for Sock Shop UI
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # TCP for Docker cluster management
  ingress {
    from_port = 2375
    to_port   = 2377
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # TCP for Docker overlay network
  ingress {
    from_port = 7946
    to_port   = 7946
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # UDP for Docker overlay network
  ingress {
    from_port = 7946
    to_port   = 7946
    protocol  = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # UDP for Docker overlay network
  ingress {
    from_port = 4789
    to_port   = 4789
    protocol  = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Any egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "nomad-consul-demo"
  }
}

data "template_file" "user_data_server_primary" {
  template = "${file("${path.root}/user-data-server.sh")}"

  vars {
    server_count      = "${var.server_count}"
    region            = "${var.region}"
    cluster_tag_value = "${var.cluster_tag_value}"
    token_for_nomad   = "${var.token_for_nomad}"
    vault_url         = "${var.vault_url}"
  }
}

data "template_file" "user_data_client" {
  template = "${file("${path.root}/user-data-client.sh")}"

  vars {
    region            = "${var.region}"
    cluster_tag_value = "${var.cluster_tag_value}"
    server_ip = "${aws_instance.primary.0.private_ip}"
    vault_url         = "${var.vault_url}"
  }
}

resource "aws_instance" "primary" {
  ami                    = "${var.ami}"
  instance_type          = "${var.server_instance_type}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.primary.id}"]
  subnet_id              = "${var.subnet_id}"
  count                  = "${var.server_count}"

  #Instance tags
  tags {
    Name = "${var.name_tag_prefix}-server-${count.index}"
    ConsulAutoJoin = "${var.cluster_tag_value}"
    owner = "${var.owner}"
    TTL = "${var.ttl}"
    created-by = "Terraform"
  }

  user_data            = "${data.template_file.user_data_server_primary.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.instance_profile.name}"
}

resource "aws_instance" "client" {
  ami                    = "${var.ami}"
  instance_type          = "${var.client_instance_type}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.primary.id}"]
  subnet_id              = "${var.subnet_id}"
  count                  = "${var.client_count}"
  depends_on             = ["aws_instance.primary"]

  #Instance tags
  tags {
    Name = "${var.name_tag_prefix}-client-${count.index}"
    ConsulAutoJoin = "${var.cluster_tag_value}"
    owner = "${var.owner}"
    TTL = "${var.ttl}"
    created-by = "Terraform"
  }

  user_data = "${data.template_file.user_data_client.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.instance_profile.name}"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = "nomadconsul"
  role        = "${aws_iam_role.instance_role.name}"
}

resource "aws_iam_role" "instance_role" {
  name_prefix        = "nomadconsul"
  assume_role_policy = "${data.aws_iam_policy_document.instance_role.json}"
}

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

resource "aws_iam_role_policy" "auto_discover_cluster" {
  name   = "auto-discover-cluster"
  role   = "${aws_iam_role.instance_role.id}"
  policy = "${data.aws_iam_policy_document.auto_discover_cluster.json}"
}

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

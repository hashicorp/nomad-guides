data "aws_ami" "base" {
  most_recent = true
  owners      = ["${var.ami_owner}"]

  filter {
    name   = "name"
    values = ["${var.ami_name}"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "consul_install" {
  template = "${file("${path.module}/../../templates/install-consul-systemd.sh.tpl")}"

  vars = {
    consul_version = "${var.consul_version}"
    consul_url     = "${var.consul_url}"
  }
}

data "template_file" "nomad_install" {
  template = "${file("${path.module}/../../templates/install-nomad-systemd.sh.tpl")}"

  vars = {
    nomad_version = "${var.nomad_version}"
    nomad_url     = "${var.nomad_url}"
  }
}

data "template_file" "bastion_quick_start" {
  template = "${file("${path.module}/../../templates/quick-start-bastion-systemd.sh.tpl")}"

  vars = {
    name         = "${var.name}"
    provider     = "${var.provider}"
    local_ip_url = "${var.local_ip_url}"
  }
}

module "network_aws" {
  source = "github.com/hashicorp-modules/network-aws?ref=f-refactor"
  # source = "../../../../../hashicorp-modules/network-aws"

  name          = "${var.name}"
  nat_count     = "1"
  bastion_count = "1"
  image_id      = "${data.aws_ami.base.id}"
  tags          = "${var.network_tags}"
  user_data     = <<EOF
${data.template_file.consul_install.rendered}
${data.template_file.nomad_install.rendered}
${data.template_file.bastion_quick_start.rendered}
EOF
}

data "template_file" "consul_quick_start" {
  template = "${file("${path.module}/../../templates/quick-start-consul-systemd.sh.tpl")}"

  vars = {
    name             = "${var.name}"
    provider         = "${var.provider}"
    local_ip_url     = "${var.local_ip_url}"
    consul_bootstrap = "${length(module.network_aws.subnet_private_ids)}"
  }
}

module "consul_aws" {
  source = "github.com/hashicorp-modules/consul-aws?ref=f-refactor"
  # source = "../../../../../hashicorp-modules/consul-aws"

  name         = "${var.name}" # Must match network_aws module name for Consul Auto Join to work
  vpc_id       = "${module.network_aws.vpc_id}"
  vpc_cidr     = "${module.network_aws.vpc_cidr_block}"
  subnet_ids   = "${module.network_aws.subnet_private_ids}"
  image_id     = "${var.consul_image_id != "" ? var.consul_image_id : data.aws_ami.base.id}"
  ssh_key_name = "${element(split(",", module.network_aws.ssh_key_name), 0)}"
  tags         = "${var.consul_tags}"
  user_data    = <<EOF
${data.template_file.consul_install.rendered} # Runtime install Consul in -dev mode
${data.template_file.consul_quick_start.rendered} # Configure Consul quick start
EOF
}

data "template_file" "nomad_server_quick_start" {
  template = "${file("${path.module}/../../templates/quick-start-nomad-server-systemd.sh.tpl")}"

  vars = {
    name            = "${var.name}"
    provider        = "${var.provider}"
    local_ip_url    = "${var.local_ip_url}"
    nomad_bootstrap = "${var.nomad_servers != "-1" ? var.nomad_servers : length(module.network_aws.subnet_private_ids)}"
  }
}

module "nomad_server_aws" {
  source = "github.com/hashicorp-modules/nomad-aws?ref=f-refactor"
  # source = "../../../../../hashicorp-modules/nomad-aws"

  name         = "${var.name}-server" # Must match network_aws module name for Consul Auto Join to work
  vpc_id       = "${module.network_aws.vpc_id}"
  vpc_cidr     = "${module.network_aws.vpc_cidr_block}"
  subnet_ids   = "${module.network_aws.subnet_private_ids}"
  count        = "${var.nomad_servers}"
  image_id     = "${var.nomad_image_id != "" ? var.nomad_image_id : data.aws_ami.base.id}"
  ssh_key_name = "${element(split(",", module.network_aws.ssh_key_name), 0)}"
  tags         = "${var.nomad_tags}"
  user_data    = <<EOF
${data.template_file.consul_install.rendered} # Runtime install Consul in -dev mode
${data.template_file.nomad_install.rendered} # Runtime install Nomad in -dev mode
${data.template_file.nomad_server_quick_start.rendered} # Configure Nomad quick start
EOF
}

data "template_file" "nomad_client_quick_start" {
  template = "${file("${path.module}/../../templates/quick-start-nomad-client-systemd.sh.tpl")}"

  vars = {
    name         = "${var.name}"
    provider     = "${var.provider}"
    local_ip_url = "${var.local_ip_url}"
  }
}

module "nomad_client_aws" {
  source = "github.com/hashicorp-modules/nomad-aws?ref=f-refactor"
  # source = "../../../../../hashicorp-modules/nomad-aws"

  name         = "${var.name}-client" # Must match network_aws module name for Consul Auto Join to work
  vpc_id       = "${module.network_aws.vpc_id}"
  vpc_cidr     = "${module.network_aws.vpc_cidr_block}"
  subnet_ids   = "${module.network_aws.subnet_private_ids}"
  count        = "${var.nomad_clients}"
  image_id     = "${var.nomad_image_id != "" ? var.nomad_image_id : data.aws_ami.base.id}"
  ssh_key_name = "${element(split(",", module.network_aws.ssh_key_name), 0)}"
  tags         = "${var.nomad_tags}"
  user_data    = <<EOF
${data.template_file.consul_install.rendered} # Runtime install Consul in -dev mode
${data.template_file.nomad_install.rendered} # Runtime install Nomad in -dev mode
${data.template_file.nomad_client_quick_start.rendered} # Configure Nomad quick start
EOF
}

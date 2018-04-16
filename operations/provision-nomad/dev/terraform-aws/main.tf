module "ssh_keypair_aws" {
  source = "github.com/hashicorp-modules/ssh-keypair-aws?ref=f-refactor"
}

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

data "template_file" "base_install" {
  template = "${file("${path.module}/../../templates/install-base.sh.tpl")}"
}

data "template_file" "consul_install" {
  template = "${file("${path.module}/../../templates/install-consul-systemd.sh.tpl")}"

  vars = {
    consul_install  = "${var.consul_install}"
    consul_version  = "${var.consul_version}"
    consul_url      = "${var.consul_url}"
    name            = "${var.name}"
    local_ip_url    = "${var.local_ip_url}"
    consul_override = "${var.consul_config_override != "" ? true : false}"
    consul_config   = "${var.consul_config_override}"
  }
}

data "template_file" "vault_install" {
  template = "${file("${path.module}/../../templates/install-vault-systemd.sh.tpl")}"

  vars = {
    vault_install  = "${var.vault_install}"
    vault_version  = "${var.vault_version}"
    vault_url      = "${var.vault_url}"
    name           = "${var.name}"
    local_ip_url   = "${var.local_ip_url}"
    vault_override = "${var.vault_config_override != "" ? true : false}"
    vault_config   = "${var.vault_config_override}"
  }
}

data "template_file" "nomad_install" {
  template = "${file("${path.module}/../../templates/install-nomad-systemd.sh.tpl")}"

  vars = {
    nomad_version  = "${var.nomad_version}"
    nomad_url      = "${var.nomad_url}"
    name           = "${var.name}"
    local_ip_url   = "${var.local_ip_url}"
    nomad_override = "${var.nomad_config_override != "" ? true : false}"
    nomad_config   = "${var.nomad_config_override}"
  }
}

data "template_file" "docker_install" {
  template = "${file("${path.module}/../../templates/install-docker.sh.tpl")}"

  vars = {
    docker_install = "${var.nomad_docker_install}"
  }
}

data "template_file" "java_install" {
  template = "${file("${path.module}/../../templates/install-java.sh.tpl")}"

  vars = {
    java_install = "${var.nomad_java_install}"
  }
}

module "network_aws" {
  source = "github.com/hashicorp-modules/network-aws?ref=f-refactor"

  name              = "${var.name}"
  vpc_cidr          = "${var.vpc_cidr}"
  vpc_cidrs_public  = "${var.vpc_cidrs_public}"
  nat_count         = "${var.nat_count}"
  vpc_cidrs_private = "${var.vpc_cidrs_private}"
  bastion_count     = "${var.bastion_count}"
  image_id          = "${var.bastion_image_id != "" ? var.bastion_image_id : data.aws_ami.base.id}"
  private_key_file  = "${module.ssh_keypair_aws.private_key_filename}"
  tags              = "${var.network_tags}"
}

module "consul_lb_aws" {
  source = "github.com/hashicorp-modules/consul-lb-aws?ref=f-refactor"

  create         = "${var.consul_install}"
  name           = "${var.name}"
  vpc_id         = "${module.network_aws.vpc_id}"
  cidr_blocks    = ["${var.nomad_public ? "0.0.0.0/0" : module.network_aws.vpc_cidr}"]
  subnet_ids     = "${split(",", var.nomad_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"
  is_internal_lb = "${!var.nomad_public}"
  tags           = "${var.nomad_tags}"
}

module "vault_lb_aws" {
  source = "github.com/hashicorp-modules/vault-lb-aws?ref=f-refactor"

  create         = "${var.vault_install}"
  name           = "${var.name}"
  vpc_id         = "${module.network_aws.vpc_id}"
  cidr_blocks    = ["${var.nomad_public ? "0.0.0.0/0" : module.network_aws.vpc_cidr}"]
  subnet_ids     = "${split(",", var.nomad_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"
  is_internal_lb = "${!var.nomad_public}"
  tags           = "${var.nomad_tags}"
}

module "nomad_aws" {
  source = "github.com/hashicorp-modules/nomad-aws?ref=f-refactor"

  name          = "${var.name}" # Must match network_aws module name for Consul Auto Join to work
  vpc_id        = "${module.network_aws.vpc_id}"
  vpc_cidr      = "${module.network_aws.vpc_cidr}"
  subnet_ids    = "${split(",", var.nomad_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"
  count         = "${var.nomad_count}"
  instance_type = "${var.nomad_instance}"
  image_id      = "${var.nomad_image_id != "" ? var.nomad_image_id : data.aws_ami.base.id}"
  public        = "${var.nomad_public}"
  ssh_key_name  = "${module.ssh_keypair_aws.name}"
  tags          = "${var.nomad_tags}"
  tags_list     = "${var.nomad_tags_list}"

  user_data = <<EOF
${data.template_file.base_install.rendered} # Runtime install base tools
${data.template_file.consul_install.rendered} # Runtime install Consul in -dev mode
${data.template_file.vault_install.rendered} # Runtime install Vault in -dev mode
${data.template_file.nomad_install.rendered} # Runtime install Nomad in -dev mode
${data.template_file.docker_install.rendered} # Runtime install Docker
${data.template_file.java_install.rendered} # Runtime install Java
EOF

  target_groups = [
  "${module.consul_lb_aws.consul_tg_http_8500_arn}",
  "${module.consul_lb_aws.consul_tg_https_8080_arn}",
  "${module.vault_lb_aws.vault_tg_http_8200_arn}",
  "${module.vault_lb_aws.vault_tg_https_8200_arn}",
  ]
}

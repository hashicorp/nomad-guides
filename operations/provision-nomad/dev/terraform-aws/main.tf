data "http" "workstation_external_ip" {
  url = "http://icanhazip.com"
}

locals {
  workstation_external_cidr = "${chomp(data.http.workstation_external_ip.body)}/32"
}

module "ssh_keypair_aws_override" {
  source = "github.com/hashicorp-modules/ssh-keypair-aws"

  create = "${var.create}"
  name   = "${var.name}-override"
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
}

data "template_file" "java_install" {
  template = "${file("${path.module}/../../templates/install-java.sh.tpl")}"
}

resource "random_string" "wetty_password" {
  count = "${var.create ? 1 : 0}"

  length           = 32
  special          = true
  override_special = "${var.override}"
}

data "template_file" "wetty_install" {
  template = "${file("${path.module}/../../templates/install-wetty.sh.tpl")}"

  vars = {
    wetty_user = "wetty-${var.name}"
    wetty_pass = "${element(concat(random_string.wetty_password.*.result, list("")), 0)}" # TODO: Workaround for issue #11210
  }
}

module "network_aws" {
  # source = "github.com/hashicorp-modules/network-aws"
  source = "../../../../../../hashicorp-modules/network-aws"

  create            = "${var.create}"
  name              = "${var.name}"
  vpc_cidr          = "${var.vpc_cidr}"
  vpc_cidrs_public  = "${var.vpc_cidrs_public}"
  nat_count         = "${var.nat_count}"
  vpc_cidrs_private = "${var.vpc_cidrs_private}"
  cidr_blocks       = "${split(",", var.nomad_public ? join(",", compact(concat(list(local.workstation_external_cidr), var.public_cidrs, list(module.network_aws.vpc_cidr)))) : module.network_aws.vpc_cidr)}" # If there's a public IP, open Nomad ports for public access - DO NOT DO THIS IN PROD
  bastion_count     = "${var.bastion_servers}"
  instance_type     = "${var.bastion_instance}"
  os                = "${replace(lower(var.ami_name), "ubuntu", "") != lower(var.ami_name) ? "Ubuntu" : replace(lower(var.ami_name), "rhel", "") != lower(var.ami_name) ? "RHEL" : "unknown"}"
  image_id          = "${var.bastion_image_id != "" ? var.bastion_image_id : data.aws_ami.base.id}"
  private_key_file  = "${module.ssh_keypair_aws_override.private_key_filename}"
  tags              = "${var.network_tags}"
  user_data         = <<EOF
${data.template_file.base_install.rendered} # Runtime install base tools
${var.consul_install ? data.template_file.consul_install.rendered : "echo \"Skip Consul install\""} # Runtime install Consul in -dev mode
${var.vault_install ? data.template_file.vault_install.rendered : "echo \"Skip Vault install\""} # Runtime install Vault in -dev mode
${data.template_file.nomad_install.rendered} # Runtime install Nomad in -dev mode
${data.template_file.wetty_install.rendered} # Runtime install Wetty on Bastion
EOF
}

module "consul_lb_aws" {
  source = "github.com/hashicorp-modules/consul-lb-aws"

  create         = "${var.consul_install}"
  name           = "${var.name}"
  vpc_id         = "${module.network_aws.vpc_id}"
  cidr_blocks    = ["${var.nomad_public ? "0.0.0.0/0" : module.network_aws.vpc_cidr}"]
  subnet_ids     = "${split(",", var.nomad_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"
  is_internal_lb = "${!var.nomad_public}"
  tags           = "${var.nomad_tags}"
}

module "vault_lb_aws" {
  source = "github.com/hashicorp-modules/vault-lb-aws"

  create         = "${var.vault_install}"
  name           = "${var.name}"
  vpc_id         = "${module.network_aws.vpc_id}"
  cidr_blocks    = ["${var.nomad_public ? "0.0.0.0/0" : module.network_aws.vpc_cidr}"]
  subnet_ids     = "${split(",", var.nomad_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"
  is_internal_lb = "${!var.nomad_public}"
  tags           = "${var.nomad_tags}"
}

module "nomad_aws" {
  # source = "github.com/hashicorp-modules/nomad-aws"
  source = "../../../../../../hashicorp-modules/nomad-aws"

  create         = "${var.create}"
  name           = "${var.name}" # Must match network_aws module name for Consul Auto Join to work
  vpc_id         = "${module.network_aws.vpc_id}"
  vpc_cidr       = "${module.network_aws.vpc_cidr}"
  subnet_ids     = "${split(",", var.nomad_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"
  count          = "${var.nomad_servers}"
  instance_type  = "${var.nomad_instance}"
  os             = "${replace(lower(var.ami_name), "ubuntu", "") != lower(var.ami_name) ? "Ubuntu" : replace(lower(var.ami_name), "rhel", "") != lower(var.ami_name) ? "RHEL" : "unknown"}"
  image_id       = "${var.nomad_image_id != "" ? var.nomad_image_id : data.aws_ami.base.id}"
  ssh_key_name   = "${module.ssh_keypair_aws_override.name}"
  lb_cidr_blocks = "${split(",", var.nomad_public ? join(",", compact(concat(list(local.workstation_external_cidr), var.public_cidrs, list(module.network_aws.vpc_cidr)))) : module.network_aws.vpc_cidr)}" # If there's a public IP, open Nomad ports for public access - DO NOT DO THIS IN PROD
  lb_internal    = "${!var.nomad_public}"
  tags           = "${var.nomad_tags}"
  tags_list      = "${var.nomad_tags_list}"

  user_data = <<EOF
${data.template_file.base_install.rendered} # Runtime install base tools
${var.consul_install ? data.template_file.consul_install.rendered : "echo \"Skip Consul install\""} # Runtime install Consul in -dev mode
${var.vault_install ? data.template_file.vault_install.rendered : "echo \"Skip Vault install\""} # Runtime install Vault in -dev mode
${data.template_file.nomad_install.rendered} # Runtime install Nomad in -dev mode
${var.nomad_docker_install ? data.template_file.docker_install.rendered : "echo \"Skip Docker install\""} # Runtime install Docker
${var.nomad_java_install ? data.template_file.java_install.rendered : "echo \"Skip Java install\""} # Runtime install Java
${data.template_file.wetty_install.rendered} # Runtime install Wetty
EOF

  target_groups = ["${compact(
    list(
      module.consul_lb_aws.consul_tg_http_8500_arn,
      module.consul_lb_aws.consul_tg_https_8080_arn,
      module.vault_lb_aws.vault_tg_http_8200_arn,
      module.vault_lb_aws.vault_tg_https_8200_arn,
    )
  )}"]
}

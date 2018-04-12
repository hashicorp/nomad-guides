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
    consul_install  = true
    consul_version  = "${var.consul_version}"
    consul_url      = "${var.consul_url}"
    name            = "${var.name}"
    local_ip_url    = "${var.local_ip_url}"
    consul_override = false
    consul_config   = ""
  }
}

data "template_file" "vault_install" {
  template = "${file("${path.module}/../../templates/install-vault-systemd.sh.tpl")}"

  vars = {
    vault_install  = true
    vault_version  = "${var.vault_version}"
    vault_url      = "${var.vault_url}"
    name           = "${var.name}"
    local_ip_url   = "${var.local_ip_url}"
    vault_override = false
    vault_config   = ""
  }
}

data "template_file" "nomad_install" {
  template = "${file("${path.module}/../../templates/install-nomad-systemd.sh.tpl")}"

  vars = {
    nomad_version  = "${var.nomad_version}"
    nomad_url      = "${var.nomad_url}"
    name           = "${var.name}"
    local_ip_url   = "${var.local_ip_url}"
    nomad_override = false
    nomad_config   = ""
  }
}

data "template_file" "bastion_quick_start" {
  template = "${file("${path.module}/../../templates/quick-start-bastion-systemd.sh.tpl")}"

  vars = {
    name            = "${var.name}"
    provider        = "${var.provider}"
    local_ip_url    = "${var.local_ip_url}"
    consul_override = "${var.consul_client_config_override != "" ? true : false}"
    consul_config   = "${var.consul_client_config_override}"
    vault_provision = "${var.vault_provision}"
  }
}

module "network_aws" {
  # source = "github.com/hashicorp-modules/network-aws?ref=f-refactor"
  source = "../../../../../../hashicorp-modules/network-aws"

  name              = "${var.name}"
  vpc_cidr          = "${var.vpc_cidr}"
  vpc_cidrs_public  = "${var.vpc_cidrs_public}"
  vpc_cidrs_private = "${var.vpc_cidrs_private}"
  nat_count         = "${var.nat_count}"
  bastion_count     = "${var.bastion_count}"
  instance_type     = "${var.bastion_instance}"
  image_id          = "${var.bastion_image_id != "" ? var.bastion_image_id : data.aws_ami.base.id}"
  tags              = "${var.network_tags}"
  user_data         = <<EOF
${data.template_file.base_install.rendered} # Runtime install base tools
${data.template_file.consul_install.rendered} # Runtime install Consul in -dev mod
${data.template_file.vault_install.rendered} # Runtime install Vault in -dev mode
${data.template_file.nomad_install.rendered} # Runtime install Nomad in -dev mod
${data.template_file.bastion_quick_start.rendered} # Configure Bastion quick start
EOF
}

data "template_file" "consul_quick_start" {
  template = "${file("${path.module}/../../templates/quick-start-consul-systemd.sh.tpl")}"

  vars = {
    name             = "${var.name}"
    provider         = "${var.provider}"
    local_ip_url     = "${var.local_ip_url}"
    consul_bootstrap = "${var.consul_servers != -1 ? var.consul_servers : length(module.network_aws.subnet_private_ids)}"
    consul_override  = "${var.consul_server_config_override != "" ? true : false}"
    consul_config    = "${var.consul_server_config_override}"
  }
}

module "consul_aws" {
  # source = "github.com/hashicorp-modules/consul-aws?ref=f-refactor"
  source = "../../../../../../hashicorp-modules/consul-aws"

  name          = "${var.name}" # Must match network_aws module name for Consul Auto Join to work
  vpc_id        = "${module.network_aws.vpc_id}"
  vpc_cidr      = "${module.network_aws.vpc_cidr}"
  subnet_ids    = "${split(",", var.consul_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"
  count         = "${var.consul_servers}"
  instance_type = "${var.consul_instance}"
  image_id      = "${var.consul_image_id != "" ? var.consul_image_id : data.aws_ami.base.id}"
  public        = "${var.consul_public}"
  ssh_key_name  = "${module.network_aws.ssh_key_name}"
  tags          = "${var.consul_tags}"
  tags_list     = "${var.consul_tags_list}"
  user_data     = <<EOF
${data.template_file.base_install.rendered} # Runtime install base tools
${data.template_file.consul_install.rendered} # Runtime install Consul in -dev mode
${data.template_file.consul_quick_start.rendered} # Configure Consul quick start
EOF
}

data "template_file" "vault_quick_start" {
  template = "${file("${path.module}/../../templates/quick-start-vault-systemd.sh.tpl")}"

  vars = {
    name            = "${var.name}"
    provider        = "${var.provider}"
    local_ip_url    = "${var.local_ip_url}"
    consul_override = "${var.consul_client_config_override != "" ? true : false}"
    consul_config   = "${var.consul_client_config_override}"
    vault_override  = "${var.vault_server_config_override != "" ? true : false}"
    vault_config    = "${var.vault_server_config_override}"
  }
}

module "vault_aws" {
  # source = "github.com/hashicorp-modules/vault-aws?ref=f-refactor"
  source = "../../../../../../hashicorp-modules/vault-aws"

  create        = "${var.vault_provision}" # Provision Vault cluster
  name          = "${var.name}" # Must match network_aws module name for Consul Auto Join to work
  vpc_id        = "${module.network_aws.vpc_id}"
  vpc_cidr      = "${module.network_aws.vpc_cidr}"
  subnet_ids    = "${split(",", var.vault_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"
  count         = "${var.vault_servers}"
  instance_type = "${var.vault_instance}"
  image_id      = "${var.vault_image_id != "" ? var.vault_image_id : data.aws_ami.base.id}"
  public        = "${var.vault_public}"
  ssh_key_name  = "${module.network_aws.ssh_key_name}"
  tags          = "${var.vault_tags}"
  tags_list     = "${var.vault_tags_list}"
  user_data     = <<EOF
${data.template_file.base_install.rendered} # Runtime install base tools
${data.template_file.consul_install.rendered} # Runtime install Consul in -dev mode
${data.template_file.vault_install.rendered} # Runtime install Vault in -dev mode
${data.template_file.vault_quick_start.rendered} # Configure Vault quick start
EOF
}

data "template_file" "nomad_server_quick_start" {
  template = "${file("${path.module}/../../templates/quick-start-nomad-server-systemd.sh.tpl")}"

  vars = {
    name            = "${var.name}"
    provider        = "${var.provider}"
    local_ip_url    = "${var.local_ip_url}"
    nomad_bootstrap = "${var.nomad_servers != -1 ? var.nomad_servers : length(module.network_aws.subnet_private_ids)}"
    consul_override = "${var.consul_client_config_override != "" ? true : false}"
    consul_config   = "${var.consul_client_config_override}"
    nomad_override  = "${var.nomad_server_config_override != "" ? true : false}"
    nomad_config    = "${var.nomad_server_config_override}"
  }
}

module "nomad_server_aws" {
  # source = "github.com/hashicorp-modules/nomad-aws?ref=f-refactor"
  source = "../../../../../../hashicorp-modules/nomad-aws"

  name          = "${var.name}-server" # Must match network_aws module name for Consul Auto Join to work
  vpc_id        = "${module.network_aws.vpc_id}"
  vpc_cidr      = "${module.network_aws.vpc_cidr}"
  subnet_ids    = "${split(",", var.nomad_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"
  count         = "${var.nomad_servers}"
  instance_type = "${var.nomad_instance}"
  image_id      = "${var.nomad_image_id != "" ? var.nomad_image_id : data.aws_ami.base.id}"
  public        = "${var.nomad_public}"
  ssh_key_name  = "${module.network_aws.ssh_key_name}"
  tags          = "${var.nomad_tags}"
  tags_list     = "${var.nomad_tags_list}"
  user_data     = <<EOF
${data.template_file.base_install.rendered} # Runtime install base tools
${data.template_file.consul_install.rendered} # Runtime install Consul in -dev mode
${data.template_file.nomad_install.rendered} # Runtime install Nomad in -dev mode
${data.template_file.nomad_server_quick_start.rendered} # Configure Nomad quick start
EOF
}

data "template_file" "nomad_client_quick_start" {
  template = "${file("${path.module}/../../templates/quick-start-nomad-client-systemd.sh.tpl")}"

  vars = {
    name            = "${var.name}"
    provider        = "${var.provider}"
    local_ip_url    = "${var.local_ip_url}"
    consul_override = "${var.consul_client_config_override != "" ? true : false}"
    consul_config   = "${var.consul_client_config_override}"
    nomad_override  = "${var.nomad_client_config_override != "" ? true : false}"
    nomad_config    = "${var.nomad_client_config_override}"
  }
}

data "template_file" "docker_install" {
  template = "${file("${path.module}/../../templates/install-docker.sh.tpl")}"

  vars = {
    docker_install = "${var.nomad_client_docker_install}"
  }
}

data "template_file" "java_install" {
  template = "${file("${path.module}/../../templates/install-java.sh.tpl")}"

  vars = {
    java_install = "${var.nomad_client_java_install}"
  }
}

module "nomad_client_aws" {
  # source = "github.com/hashicorp-modules/nomad-aws?ref=f-refactor"
  source = "../../../../../../hashicorp-modules/nomad-aws"

  name          = "${var.name}-client" # Must match network_aws module name for Consul Auto Join to work
  vpc_id        = "${module.network_aws.vpc_id}"
  vpc_cidr      = "${module.network_aws.vpc_cidr}"
  subnet_ids    = "${split(",", var.nomad_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"
  count         = "${var.nomad_clients}"
  instance_type = "${var.nomad_instance}"
  image_id      = "${var.nomad_image_id != "" ? var.nomad_image_id : data.aws_ami.base.id}"
  public        = "${var.nomad_public}"
  ssh_key_name  = "${module.network_aws.ssh_key_name}"
  tags          = "${var.nomad_tags}"
  tags_list     = "${var.nomad_tags_list}"
  user_data     = <<EOF
${data.template_file.base_install.rendered} # Runtime install base tools
${data.template_file.consul_install.rendered} # Runtime install Consul in -dev mode
${data.template_file.nomad_install.rendered} # Runtime install Nomad in -dev mode
${data.template_file.nomad_client_quick_start.rendered} # Configure Nomad quick start
${data.template_file.docker_install.rendered} # Runtime install Docker
${data.template_file.java_install.rendered} # Runtime install Java
EOF
}

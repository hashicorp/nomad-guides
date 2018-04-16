module "ssh_keypair_aws_override" {
  source = "github.com/hashicorp-modules/ssh-keypair-aws?ref=f-refactor"

  name = "${var.name}-override"
}

module "consul_auto_join_instance_role" {
  source = "github.com/hashicorp-modules/consul-auto-join-instance-role-aws?ref=f-refactor"

  name = "${var.name}"
}

resource "random_id" "consul_encrypt" {
  byte_length = 16
}

resource "random_id" "nomad_encrypt" {
  byte_length = 16
}

module "root_tls_self_signed_ca" {
   source = "github.com/hashicorp-modules/tls-self-signed-cert?ref=f-refactor"

  name              = "${var.name}-root"
  ca_common_name    = "${var.common_name}"
  organization_name = "${var.organization_name}"
  common_name       = "${var.common_name}"
  download_certs    = "${var.download_certs}"

  validity_period_hours = "8760"

  ca_allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

module "leaf_tls_self_signed_cert" {
  source = "github.com/hashicorp-modules/tls-self-signed-cert?ref=f-refactor"

  name              = "${var.name}-leaf"
  organization_name = "${var.organization_name}"
  common_name       = "${var.common_name}"
  ca_override       = true
  ca_key_override   = "${module.root_tls_self_signed_ca.ca_private_key_pem}"
  ca_cert_override  = "${module.root_tls_self_signed_ca.ca_cert_pem}"
  download_certs    = "${var.download_certs}"

  validity_period_hours = "8760"

  dns_names = [
    "localhost",
    "*.node.consul",
    "*.service.consul",
    "server.dc1.consul",
    "*.dc1.consul",
    "server.${var.name}.consul",
    "*.${var.name}.consul",
    "server.global.nomad",
    "*.global.nomad",
    "server.${var.name}.nomad",
    "*.${var.name}.nomad",
    "client.global.nomad",
    "*.global.nomad",
    "client.${var.name}.nomad",
    "*.${var.name}.nomad",
  ]

  ip_addresses = [
    "0.0.0.0",
    "127.0.0.1",
  ]

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

data "template_file" "bastion_user_data" {
  template = "${file("${path.module}/../../templates/best-practices-bastion-systemd.sh.tpl")}"

  vars = {
    name            = "${var.name}"
    provider        = "${var.provider}"
    local_ip_url    = "${var.local_ip_url}"
    ca_crt          = "${module.root_tls_self_signed_ca.ca_cert_pem}"
    leaf_crt        = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
    leaf_key        = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
    consul_encrypt  = "${random_id.consul_encrypt.b64_std}"
    consul_override = "${var.consul_client_config_override != "" ? true : false}"
    consul_config   = "${var.consul_client_config_override}"
    vault_provision = "${var.vault_provision}"
  }
}

module "network_aws" {
  source = "github.com/hashicorp-modules/network-aws?ref=f-refactor"

  name              = "${var.name}"
  vpc_cidr          = "${var.vpc_cidr}"
  vpc_cidrs_public  = "${var.vpc_cidrs_public}"
  nat_count         = "${var.nat_count}"
  vpc_cidrs_private = "${var.vpc_cidrs_private}"
  release_version   = "${var.bastion_release}"
  consul_version    = "${var.bastion_consul_version}"
  vault_version     = "${var.bastion_vault_version}"
  nomad_version     = "${var.bastion_nomad_version}"
  os                = "${var.bastion_os}"
  os_version        = "${var.bastion_os_version}"
  bastion_count     = "${var.bastion_count}"
  instance_profile  = "${module.consul_auto_join_instance_role.instance_profile_id}" # Override instance_profile
  instance_type     = "${var.bastion_instance}"
  image_id          = "${var.bastion_image_id}"
  user_data         = "${data.template_file.bastion_user_data.rendered}" # Override user_data
  ssh_key_name      = "${module.ssh_keypair_aws_override.name}"
  ssh_key_override  = true
  private_key_file  = "${module.ssh_keypair_aws_override.private_key_filename}"
  tags              = "${var.network_tags}"
}

data "template_file" "consul_user_data" {
  template = "${file("${path.module}/../../templates/best-practices-consul-systemd.sh.tpl")}"

  vars = {
    name             = "${var.name}"
    provider         = "${var.provider}"
    local_ip_url     = "${var.local_ip_url}"
    ca_crt           = "${module.root_tls_self_signed_ca.ca_cert_pem}"
    leaf_crt         = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
    leaf_key         = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
    consul_bootstrap = "${length(module.network_aws.subnet_private_ids)}"
    consul_encrypt   = "${random_id.consul_encrypt.b64_std}"
    consul_override  = "${var.consul_client_config_override != "" ? true : false}"
    consul_config    = "${var.consul_client_config_override}"
  }
}

module "consul_aws" {
  source = "github.com/hashicorp-modules/consul-aws?ref=f-refactor"

  name             = "${var.name}" # Must match network_aws module name for Consul Auto Join to work
  vpc_id           = "${module.network_aws.vpc_id}"
  vpc_cidr         = "${module.network_aws.vpc_cidr}"
  subnet_ids       = "${split(",", var.vault_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"
  release_version  = "${var.consul_release}"
  consul_version   = "${var.consul_version}"
  os               = "${var.consul_os}"
  os_version       = "${var.consul_os_version}"
  count            = "${var.consul_servers}"
  instance_profile = "${module.consul_auto_join_instance_role.instance_profile_id}" # Override instance_profile
  instance_type    = "${var.consul_instance}"
  image_id         = "${var.consul_image_id}"
  public           = "${var.consul_public}"
  use_lb_cert      = true
  lb_cert          = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
  lb_private_key   = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
  lb_cert_chain    = "${module.root_tls_self_signed_ca.ca_cert_pem}"
  user_data        = "${data.template_file.consul_user_data.rendered}" # Custom user_data
  ssh_key_name     = "${module.ssh_keypair_aws_override.name}"
  tags             = "${var.consul_tags}"
  tags_list        = "${var.consul_tags_list}"
}

data "template_file" "vault_user_data" {
  template = "${file("${path.module}/../../templates/best-practices-vault-systemd.sh.tpl")}"

  vars = {
    name            = "${var.name}"
    provider        = "${var.provider}"
    local_ip_url    = "${var.local_ip_url}"
    ca_crt          = "${module.root_tls_self_signed_ca.ca_cert_pem}"
    leaf_crt        = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
    leaf_key        = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
    consul_encrypt  = "${random_id.consul_encrypt.b64_std}"
    consul_override = "${var.consul_client_config_override != "" ? true : false}"
    consul_config   = "${var.consul_client_config_override}"
    vault_encrypt   = "${random_id.consul_encrypt.b64_std}"
    vault_override  = "${var.vault_server_config_override != "" ? true : false}"
    vault_config    = "${var.vault_server_config_override}"
  }
}

module "vault_aws" {
  source = "github.com/hashicorp-modules/vault-aws?ref=f-refactor"

  create           = "${var.vault_provision}" # Provision Vault cluster
  name             = "${var.name}" # Must match network_aws module name for Consul Auto Join to work
  vpc_id           = "${module.network_aws.vpc_id}"
  vpc_cidr         = "${module.network_aws.vpc_cidr}"
  subnet_ids       = "${split(",", var.vault_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"
  release_version  = "${var.vault_release}"
  vault_version    = "${var.vault_version}"
  consul_version   = "${var.consul_version}"
  os               = "${var.vault_os}"
  os_version       = "${var.vault_os_version}"
  count            = "${var.vault_servers}"
  instance_profile = "${module.consul_auto_join_instance_role.instance_profile_id}" # Override instance_profile
  instance_type    = "${var.vault_instance}"
  image_id         = "${var.vault_image_id}"
  public           = "${var.vault_public}"
  use_lb_cert      = true
  lb_cert          = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
  lb_private_key   = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
  lb_cert_chain    = "${module.root_tls_self_signed_ca.ca_cert_pem}"
  user_data        = "${data.template_file.vault_user_data.rendered}" # Custom user_data
  ssh_key_name     = "${module.ssh_keypair_aws_override.name}"
  tags             = "${var.vault_tags}"
  tags_list        = "${var.vault_tags_list}"
}

data "template_file" "nomad_server_best_practices" {
  template = "${file("${path.module}/../../templates/best-practices-nomad-server-systemd.sh.tpl")}"

  vars = {
    name            = "${var.name}"
    provider        = "${var.provider}"
    local_ip_url    = "${var.local_ip_url}"
    ca_crt          = "${module.root_tls_self_signed_ca.ca_cert_pem}"
    leaf_crt        = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
    leaf_key        = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
    consul_encrypt  = "${random_id.consul_encrypt.b64_std}"
    consul_override = "${var.consul_client_config_override != "" ? true : false}"
    consul_config   = "${var.consul_client_config_override}"
    nomad_bootstrap = "${var.nomad_servers != -1 ? var.nomad_servers : length(module.network_aws.subnet_private_ids)}"
    nomad_encrypt   = "${random_id.nomad_encrypt.b64_std}"
    nomad_override  = "${var.nomad_server_config_override != "" ? true : false}"
    nomad_config    = "${var.nomad_server_config_override}"
  }
}

module "nomad_server_aws" {
  source = "github.com/hashicorp-modules/nomad-aws?ref=f-refactor"

  name             = "${var.name}-server" # Must match network_aws module name for Consul Auto Join to work
  vpc_id           = "${module.network_aws.vpc_id}"
  vpc_cidr         = "${module.network_aws.vpc_cidr}"
  subnet_ids       = "${split(",", var.vault_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"
  release_version  = "${var.nomad_release}"
  nomad_version    = "${var.nomad_version}"
  consul_version   = "${var.consul_version}"
  os               = "${var.nomad_os}"
  os_version       = "${var.nomad_os_version}"
  count            = "${var.nomad_servers}"
  instance_profile = "${module.consul_auto_join_instance_role.instance_profile_id}" # Override instance_profile
  instance_type    = "${var.nomad_instance}"
  image_id         = "${var.nomad_image_id}"
  public           = "${var.nomad_public}"
  use_lb_cert      = true
  lb_cert          = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
  lb_private_key   = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
  lb_cert_chain    = "${module.root_tls_self_signed_ca.ca_cert_pem}"
  user_data        = "${data.template_file.nomad_server_best_practices.rendered}" # Custom user_data
  ssh_key_name     = "${module.ssh_keypair_aws_override.name}"
  tags             = "${var.nomad_tags}"
  tags_list        = "${var.nomad_tags_list}"
}

data "template_file" "nomad_client_best_practices" {
  template = "${file("${path.module}/../../templates/best-practices-nomad-client-systemd.sh.tpl")}"

  vars = {
    name            = "${var.name}"
    provider        = "${var.provider}"
    local_ip_url    = "${var.local_ip_url}"
    ca_crt          = "${module.root_tls_self_signed_ca.ca_cert_pem}"
    leaf_crt        = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
    leaf_key        = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
    consul_encrypt  = "${random_id.consul_encrypt.b64_std}"
    consul_override = "${var.consul_client_config_override != "" ? true : false}"
    consul_config   = "${var.consul_client_config_override}"
    nomad_encrypt   = "${random_id.nomad_encrypt.b64_std}"
    nomad_override  = "${var.nomad_client_config_override != "" ? true : false}"
    nomad_config    = "${var.nomad_client_config_override}"
  }
}

module "nomad_client_aws" {
  source = "github.com/hashicorp-modules/nomad-aws?ref=f-refactor"

  name             = "${var.name}-client" # Must match network_aws module name for Consul Auto Join to work
  vpc_id           = "${module.network_aws.vpc_id}"
  vpc_cidr         = "${module.network_aws.vpc_cidr}"
  subnet_ids       = "${split(",", var.vault_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"
  release_version  = "${var.nomad_release}"
  nomad_version    = "${var.nomad_version}"
  consul_version   = "${var.consul_version}"
  os               = "${var.nomad_os}"
  os_version       = "${var.nomad_os_version}"
  count            = "${var.nomad_clients}"
  instance_profile = "${module.consul_auto_join_instance_role.instance_profile_id}" # Override instance_profile
  instance_type    = "${var.nomad_instance}"
  image_id         = "${var.nomad_image_id}"
  public           = "${var.nomad_public}"
  use_lb_cert      = true
  lb_cert          = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
  lb_private_key   = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
  lb_cert_chain    = "${module.root_tls_self_signed_ca.ca_cert_pem}"
  user_data        = "${data.template_file.nomad_client_best_practices.rendered}" # Custom user_data
  ssh_key_name     = "${module.ssh_keypair_aws_override.name}"
  tags             = "${var.nomad_tags}"
  tags_list        = "${var.nomad_tags_list}"
}

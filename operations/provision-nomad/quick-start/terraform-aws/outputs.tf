output "zREADME" {
  value = <<README

Your "${var.name}" AWS Nomad Quick Start cluster has been
successfully provisioned!

${module.network_aws.zREADME}
# ------------------------------------------------------------------------------
# Local HTTP API Requests
# ------------------------------------------------------------------------------

If you're making HTTP API requests outside the Bastion (locally), set
the below env vars.

The `nomad_public`, `consul_public`, and `vault_public` variables must be set
to true for requests to work.

`nomad_public`: ${var.nomad_public}
`consul_public`: ${var.consul_public}
`vault_provision`: ${var.vault_provision}
`vault_public`: ${var.vault_public}

  $ export NOMAD_ADDR=http://${module.nomad_server_aws.nomad_lb_dns}:4646
  $ export CONSUL_ADDR=http://${module.consul_aws.consul_lb_dns}:8500${var.vault_provision ? format("\n  $ export VAULT_ADDR=http://%s:8200", module.vault_aws.vault_lb_dns) : ""}

# ------------------------------------------------------------------------------
# Nomad Quick Start
# ------------------------------------------------------------------------------

Once on the Bastion host, you can use Consul's DNS functionality to seamlessly
SSH into other Consul or Nomad nodes if they exist.

  $ ssh -A ${module.nomad_server_aws.nomad_username}@nomad.service.consul
  $ ssh -A ${module.nomad_client_aws.nomad_username}@nomad-client.service.consul
  $ ssh -A ${module.consul_aws.consul_username}@consul.service.consul
  ${var.vault_provision ? "\n  # Vault must be initialized & unsealed for this command to work\n  $ ssh -A ${module.vault_aws.vault_username}@vault.service.consul\n" : ""}
${module.nomad_server_aws.zREADME}
${module.consul_aws.zREADME}
${var.vault_provision ?
"${module.vault_aws.zREADME}
# ------------------------------------------------------------------------------
# Nomad Quick Start - Vault Integration
# ------------------------------------------------------------------------------

The Vault integration for Nomad can be enabled by initializing Vault
and running the below commands.

  $ export VAULT_TOKEN=<ROOT_TOKEN>
  $ consul exec -node ${var.name}-server-nomad - <<EOF
echo \"VAULT_TOKEN=$VAULT_TOKEN\" | sudo tee -a /etc/nomad.d/nomad.conf

cat <<CONFIG | sudo tee /etc/nomad.d/z-vault.hcl
vault {
  enabled = true
  address = \"http://vault.service.consul:8200\"

  tls_skip_verify = true
}
CONFIG

sudo systemctl restart nomad
EOF

  $ consul exec -node ${var.name}-client-nomad - <<EOF
cat <<CONFIG | sudo tee /etc/nomad.d/z-vault.hcl
vault {
  enabled = true
  address = \"http://vault.service.consul:8200\"

  tls_skip_verify = true
}
CONFIG

sudo systemctl restart nomad
EOF" : ""}
README
}

output "vpc_cidr" {
  value = "${module.network_aws.vpc_cidr}"
}

output "vpc_id" {
  value = "${module.network_aws.vpc_id}"
}

output "subnet_public_ids" {
  value = "${module.network_aws.subnet_public_ids}"
}

output "subnet_private_ids" {
  value = "${module.network_aws.subnet_private_ids}"
}

output "bastion_security_group" {
  value = "${module.network_aws.bastion_security_group}"
}

output "bastion_ips_public" {
  value = "${module.network_aws.bastion_ips_public}"
}

output "bastion_username" {
  value = "${module.network_aws.bastion_username}"
}

output "private_key_name" {
  value = "${module.network_aws.private_key_name}"
}

output "private_key_filename" {
  value = "${module.network_aws.private_key_filename}"
}

output "private_key_pem" {
  value = "${module.network_aws.private_key_pem}"
}

output "public_key_pem" {
  value = "${module.network_aws.public_key_pem}"
}

output "public_key_openssh" {
  value = "${module.network_aws.public_key_openssh}"
}

output "ssh_key_name" {
  value = "${module.network_aws.ssh_key_name}"
}

output "consul_asg_id" {
  value = "${module.consul_aws.consul_asg_id}"
}

output "consul_sg_id" {
  value = "${module.consul_aws.consul_sg_id}"
}

output "consul_lb_sg_id" {
  value = "${module.consul_aws.consul_lb_sg_id}"
}

output "consul_tg_http_8500_arn" {
  value = "${module.consul_aws.consul_tg_http_8500_arn}"
}

output "consul_lb_dns" {
  value = "${module.consul_aws.consul_lb_dns}"
}

output "vault_asg_id" {
  value = "${module.vault_aws.vault_asg_id}"
}

output "vault_sg_id" {
  value = "${module.vault_aws.vault_sg_id}"
}

output "vault_lb_sg_id" {
  value = "${module.vault_aws.vault_lb_sg_id}"
}

output "vault_tg_http_8200_arn" {
  value = "${module.vault_aws.vault_tg_http_8200_arn}"
}

output "vault_lb_dns" {
  value = "${module.vault_aws.vault_lb_dns}"
}

output "nomad_server_asg_id" {
  value = "${module.nomad_server_aws.nomad_asg_id}"
}

output "nomad_server_sg_id" {
  value = "${module.nomad_server_aws.nomad_sg_id}"
}

output "nomad_server_lb_sg_id" {
  value = "${module.nomad_server_aws.nomad_lb_sg_id}"
}

output "nomad_server_tg_http_4646_arn" {
  value = "${module.nomad_server_aws.nomad_tg_http_4646_arn}"
}

output "nomad_server_lb_dns" {
  value = "${module.nomad_server_aws.nomad_lb_dns}"
}

output "nomad_client_asg_id" {
  value = "${module.nomad_client_aws.nomad_asg_id}"
}

output "nomad_client_sg_id" {
  value = "${module.nomad_client_aws.nomad_sg_id}"
}

output "nomad_client_lb_sg_id" {
  value = "${module.nomad_client_aws.nomad_lb_sg_id}"
}

output "nomad_client_tg_http_4646_arn" {
  value = "${module.nomad_client_aws.nomad_tg_http_4646_arn}"
}

output "nomad_client_tg_https_4646_arn" {
  value = "${module.nomad_client_aws.nomad_tg_https_4646_arn}"
}

output "nomad_client_lb_dns" {
  value = "${module.nomad_client_aws.nomad_lb_dns}"
}

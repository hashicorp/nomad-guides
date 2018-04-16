output "zREADME" {
  value = <<README

Your "${var.name}" AWS Nomad Quick Start cluster has been
successfully provisioned!

${module.network_aws.zREADME}
# ------------------------------------------------------------------------------
# Nomad Quick Start
# ------------------------------------------------------------------------------

Once on the Bastion host, you can use Consul's DNS functionality to seamlessly
SSH into other Consul or Nomad nodes if they exist.

  $ ssh -A ${module.nomad_server_aws.nomad_username}@nomad.service.consul
  $ ssh -A ${module.nomad_client_aws.nomad_username}@nomad-client.service.consul
  $ ssh -A ${module.consul_aws.consul_username}@consul.service.consul
  ${var.vault_provision ? "# Vault must be initialized & unsealed for this command to work\n  $ ssh -A ${module.vault_aws.vault_username}@vault.service.consul\n" : ""}
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

output "nomad_server_asg_id" {
  value = "${module.nomad_server_aws.nomad_asg_id}"
}

output "nomad_server_sg_id" {
  value = "${module.nomad_server_aws.nomad_sg_id}"
}

output "nomad_client_asg_id" {
  value = "${module.nomad_client_aws.nomad_asg_id}"
}

output "nomad_client_sg_id" {
  value = "${module.nomad_client_aws.nomad_sg_id}"
}

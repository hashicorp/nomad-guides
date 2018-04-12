output "zREADME" {
  value = <<README

Your "${var.name}" AWS Nomad dev cluster has been successfully provisioned!

${module.network_aws.zREADME}To force the generation of a new key, the private key instance can be "tainted" using the below command.

  $ terraform taint -module=ssh_keypair_aws_override.tls_private_key tls_private_key.key

# ------------------------------------------------------------------------------
# Nomad Dev
# ------------------------------------------------------------------------------

${join("\n", compact(
  list(
    format("View the Nomad UI: %s", module.nomad_aws.nomad_lb_dns),
    var.consul_install ? format("View the Consul UI: %s", module.consul_lb_aws.consul_lb_dns) : "",
    var.vault_install && var.vault_url != "" ? format("View the Vault UI: %s", module.vault_lb_aws.vault_lb_dns) : "",
  ),
))}

You can SSH into the Nomad node by updating the "PUBLIC_IP" and running the
below command.

  $ ${format("ssh -A -i %s %s@%s", module.ssh_keypair_aws.private_key_filename, module.nomad_aws.nomad_username, "PUBLIC_IP")}

${module.nomad_aws.zREADME}
${var.vault_install ?
"# ------------------------------------------------------------------------------
# Nomad Dev - Vault Integration
# ------------------------------------------------------------------------------

If Vault is running in -dev mode using the in-mem storage backend (default), the
Vault integration for Nomad can be enabled by simply uncommenting the
\"nomad_config_override\" input variable in `terraform.auto.tfvars`.

Alternatively, you can run the below commands to enable the integration. This
is the best method if you're overridding the default -dev mode configuration
with a storage backed other than in-mem (e.g. uncommenting
\"vault_config_override\" input variable in `terraform.auto.tfvars`).

\"disable_remote_exec\" must be set to `false` in Consul for remote exec to
work, this can be achieved by uncommenting \"consul_config_override\" in
`terraform.auto.tfvars`.

`VAULT_TOKEN` is automatically set to \"root\" for you if running in -dev mode
with the in-mem storage backend (default), otherwise you'll need to set this
to the root token generated during `vault operator init`.

  $ echo $VAULT_TOKEN
  $ export VAULT_TOKEN=<ROOT_TOKEN>
  $ consul exec -service nomad - <<EOF
echo \"VAULT_TOKEN=$VAULT_TOKEN\" | sudo tee -a /etc/nomad.d/nomad.conf

cat <<CONFIG | sudo tee /etc/nomad.d/z-vault.hcl
vault {
  enabled = true
  address = \"http://127.0.0.1:8200\"

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

output "private_key_name" {
  value = "${module.ssh_keypair_aws.private_key_name}"
}

output "private_key_filename" {
  value = "${module.ssh_keypair_aws.private_key_filename}"
}

output "private_key_pem" {
  value = "${module.ssh_keypair_aws.private_key_pem}"
}

output "public_key_pem" {
  value = "${module.ssh_keypair_aws.public_key_pem}"
}

output "public_key_openssh" {
  value = "${module.ssh_keypair_aws.public_key_openssh}"
}

output "ssh_key_name" {
  value = "${module.ssh_keypair_aws.name}"
}

output "nomad_asg_id" {
  value = "${module.nomad_aws.nomad_asg_id}"
}

output "nomad_sg_id" {
  value = "${module.nomad_aws.nomad_sg_id}"
}

output "nomad_lb_sg_id" {
  value = "${module.nomad_aws.nomad_lb_sg_id}"
}

output "nomad_tg_http_4646_arn" {
  value = "${module.nomad_aws.nomad_tg_http_4646_arn}"
}

output "nomad_tg_https_4646_arn" {
  value = "${module.nomad_aws.nomad_tg_https_4646_arn}"
}

output "nomad_lb_dns" {
  value = "${module.nomad_aws.nomad_lb_dns}"
}

output "consul_lb_sg_id" {
  value = "${module.consul_lb_aws.consul_lb_sg_id}"
}

output "consul_tg_http_8500_arn" {
  value = "${module.consul_lb_aws.consul_tg_http_8500_arn}"
}

output "consul_tg_https_8500_arn" {
  value = "${module.consul_lb_aws.consul_tg_https_8500_arn}"
}

output "consul_lb_dns" {
  value = "${module.consul_lb_aws.consul_lb_dns}"
}

output "vault_lb_sg_id" {
  value = "${module.vault_lb_aws.vault_lb_sg_id}"
}

output "vault_tg_http_8200_arn" {
  value = "${module.vault_lb_aws.vault_tg_http_8200_arn}"
}

output "vault_tg_https_8200_arn" {
  value = "${module.vault_lb_aws.vault_tg_https_8200_arn}"
}

output "vault_lb_dns" {
  value = "${module.vault_lb_aws.vault_lb_dns}"
}

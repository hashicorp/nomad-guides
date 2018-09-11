output "zREADME" {
  value = <<README

Your "${var.name}" AWS Consul Quick Start cluster has been
successfully provisioned!

${module.network_aws.zREADME}
# ------------------------------------------------------------------------------
# External Cluster Access
# ------------------------------------------------------------------------------

If you'd like to interact with your cluster externally, use one of the below
options.

The `consul_public` variable must be set to true for any of these options to work.

`consul_public`: ${var.consul_public}

Below are the list of CIDRs that are whitelisted to have external access. This
list is populated from the "public_cidrs" variable merged with the external cidr
of the local workstation running Terraform for ease of use. If your CIDR does not
appear in the list, you can find it by googling "What is my ip" and add it to the
"public_cidrs" Terraform variable.

`public_cidrs`:
  ${join("\n  ", compact(concat(list(local.workstation_external_cidr), var.public_cidrs)))}

1.) Use Wetty (Web + tty), a web terminal for the cluster over HTTP and HTTPS

  ${join("\n  ", formatlist("%s Wetty Url: http://%s:3030/wetty", list("Bastion", "Consul"), list(element(concat(module.network_aws.bastion_ips_public, list("")), 0), module.consul_aws.consul_lb_dns)))}
  Wetty Username: wetty-${var.name}
  Wetty Password: ${element(concat(random_string.wetty_password.*.result, list("")), 0)}

2.) Set the below env var(s) and use Consul's CLI or HTTP API

  ${format("$ export CONSUL_ADDR=http://%s:8500", module.consul_aws.consul_lb_dns)}
  ${format("$ export CONSUL_HTTP_ADDR=http://%s:8500", module.consul_aws.consul_lb_dns)}

# ------------------------------------------------------------------------------
# Consul Quick Start
# ------------------------------------------------------------------------------

Once on the Bastion host, you can use Consul's DNS functionality to seamlessly
SSH into other Consul or Nomad nodes if they exist.

  $ ssh -A ${module.consul_aws.consul_username}@consul.service.consul

If public, you can SSH into the Consul nodes directly through the LB.

  $ ${format("ssh -A -i %s %s@%s", module.network_aws.private_key_filename, module.consul_aws.consul_username, module.consul_aws.consul_lb_dns)}

${module.consul_aws.zREADME}
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

output "bastion_sg_id" {
  value = "${module.network_aws.bastion_sg_id}"
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

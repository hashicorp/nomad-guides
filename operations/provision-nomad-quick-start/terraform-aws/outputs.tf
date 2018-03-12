output "zREADME" {
  value = <<README
Your AWS Nomad cluster has been successfully provisioned!

A private RSA key named "${module.network_aws.private_key_filename}" has been generated and downloaded locally. The file permissions have been changed to 0600 so the key can be used immediately for SSH or scp.

Run the below command to add this private key to the list maintained by ssh-agent so you're not prompted for it when using SSH or scp to connect to hosts with your public key.

  ssh-add ${module.network_aws.private_key_filename}

The public part of the key loaded into the agent ("public_key_openssh" output) has been placed on the target system in ~/.ssh/authorized_keys.

To SSH into a Bastion host using this private key, run one of the below commands.

  ${join("\n  ", formatlist("$ ssh -A -i %s %s@%s", module.network_aws.private_key_filename, module.network_aws.bastion_username, module.network_aws.bastion_ips_public))}

You can now interact with Nomad using any of the CLI (https://www.nomadproject.io/docs/commands/index.html) or API (https://www.nomadproject.io/api/index.html) commands.

  $ nomad server-members # Check Nomad's server members
  $ nomad node-status # Check Nomad's client nodes
  $ nomad init # Create a skeletion job file to deploy a Redis Docker container

  # Use the CLI to deploy a Redis Docker container
  $ nomad plan example.nomad # Run a nomad plan on the example job
  $ nomad run example.nomad # Run the example job
  $ nomad status # Check that the job is running
  $ nomad status example # Check job details
  $ nomad stop example # Stop the example job
  $ nomad status # Check that the job is stopped

  # Use the API to deploy a Redis Docker container
  $ nomad run -output example.nomad > example.json # Convert the example Nomad HCL job file to JSON
  $ curl \
      -X POST \
      -d @example.json \
      http://nomad-server.service.consul:4646/v1/job/example/plan | jq '.' # Run a nomad plan on the example job
  $ curl \
      -X POST \
      -d @example.json \
      http://nomad-server.service.consul:4646/v1/job/example | jq '.' # Run the example job
  $ curl \
      -X GET \
      http://nomad-server.service.consul:4646/v1/jobs | jq '.' # Check that the job is running
  $ curl \
      -X GET \
      http://nomad-server.service.consul:4646/v1/job/example | jq '.' # Check job details
  $ curl \
      -X DELETE \
      http://nomad-server.service.consul:4646/v1/job/example | jq '.' # Stop the example job
  $ curl \
      -X GET \
      http://nomad-server.service.consul:4646/v1/jobs | jq '.' # Check that the job is stopped

Once on the Bastion host, you can use Consul's DNS functionality to seemlessly SSH into other Consul or Nomad nodes.

  $ ssh -A ${module.consul_aws.consul_username}@consul.service.consul
  $ ssh -A ${module.nomad_server_aws.nomad_username}@nomad-server.service.consul
  $ ssh -A ${module.nomad_client_aws.nomad_username}@nomad-client.service.consul

To force the generation of a new key, the private key instance can be "tainted" using the below command.

  $ terraform taint -module=network_aws.ssh_keypair_aws.tls_private_key tls_private_key.key

Below are output variables that are currently commented out to reduce clutter. If you need the value of a certain output variable, such as "private_key_pem", just uncomment in outputs.tf.

 - "vpc_cidr_block"
 - "vpc_id"
 - "subnet_public_ids"
 - "subnet_private_ids"
 - "bastion_security_group"
 - "bastion_ips_public"
 - "bastion_username"
 - "private_key_name"
 - "private_key_filename"
 - "private_key_pem"
 - "public_key_pem"
 - "public_key_openssh"
 - "ssh_key_name"
 - "nomad_server_asg_id"
 - "nomad_server_sg_id"
 - "nomad_client_asg_id"
 - "nomad_client_sg_id"
README
}

/*
output "vpc_cidr_block" {
  value = "${module.network_aws.vpc_cidr_block}"
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
*/

output "zREADME" {
  value = <<README
Your "${var.name}" Nomad cluster has been successfully provisioned!

A private RSA key has been generated and downloaded locally. The file permissions have been changed to 0600 so the key can be used immediately for SSH or scp.

Run the below command to add this private key to the list maintained by ssh-agent so you're not prompted for it when using SSH or scp to connect to hosts with your public key.

  ${join("\n  ", formatlist("ssh-add %s", module.ssh_keypair_aws.private_key_filename))}

The public part of the key loaded into the agent ("public_key_openssh" output) has been placed on the target system in ~/.ssh/authorized_keys.

To SSH into a Nomad host using this private key, run the below command after replacing "HOST" with the public IP of one of the provisioned Nomad hosts.

  ${join("\n  ", formatlist("ssh -A -i %s %s@HOST", module.ssh_keypair_aws.private_key_filename, module.nomad_aws.nomad_username))}

You can now interact with Nomad using any of the CLI (https://www.nomadproject.io/docs/commands/index.html) or API (https://www.nomadproject.io/api/index.html) commands.

  $ nomad server-members # Check Nomad's server members
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
      http://127.0.0.1:4646/v1/job/example/plan | jq '.' # Run a nomad plan on the example job
  $ curl \
      -X POST \
      -d @example.json \
      http://127.0.0.1:4646/v1/job/example | jq '.' # Run the example job
  $ curl \
      -X GET \
      http://127.0.0.1:4646/v1/jobs | jq '.' # Check that the job is running
  $ curl \
      -X GET \
      http://127.0.0.1:4646/v1/job/example | jq '.' # Check job details
  $ curl \
      -X DELETE \
      http://127.0.0.1:4646/v1/job/example | jq '.' # Stop the example job
  $ curl \
      -X GET \
      http://127.0.0.1:4646/v1/jobs | jq '.' # Check that the job is stopped

Because this is a development environment, the Nomad nodes are in a public subnet with SSH access open from the outside. WARNING - DO NOT DO THIS IN PRODUCTION!

Below are output variables that are currently commented out to reduce clutter. If you need the value of a certain output variable, such as "private_key_pem", just uncomment in outputs.tf.

 - "vpc_cidr_block"
 - "vpc_id"
 - "subnet_public_ids"
 - "subnet_private_ids"
 - "private_key_name"
 - "private_key_filename"
 - "private_key_pem"
 - "public_key_pem"
 - "public_key_openssh"
 - "ssh_key_name"
 - "nomad_asg_id"
 - "nomad_sg_id"
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
*/

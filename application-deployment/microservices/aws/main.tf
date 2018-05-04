terraform {
  required_version = ">= 0.11.3"
}

provider "vault" {
  address = "${var.vault_url}"
}

data "vault_generic_secret" "aws_auth" {
  path = "aws-tf/creds/deploy"
}

# Insert 15 second delay so AWS credentials definitely available
# at all AWS endpoints
data "external" "region" {
  # Delay so that new keys are available across AWS
  program = ["./delay-vault-aws", "${var.region}"]
}

provider "aws" {
  region = "${data.external.region.result["region"]}"
  access_key = "${data.vault_generic_secret.aws_auth.data["access_key"]}"
  secret_key = "${data.vault_generic_secret.aws_auth.data["secret_key"]}"
}

module "nomadconsul" {
  source = "modules/nomadconsul"

  region            = "${var.region}"
  ami               = "${var.ami}"
  vpc_id            = "${aws_vpc.sockshop.id}"
  subnet_id         = "${aws_subnet.public-subnet.id}"
  server_instance_type     = "${var.server_instance_type}"
  client_instance_type     = "${var.client_instance_type}"
  key_name          = "${var.key_name}"
  server_count      = "${var.server_count}"
  client_count      = "${var.client_count}"
  name_tag_prefix   = "${var.name_tag_prefix}"
  cluster_tag_value = "${var.cluster_tag_value}"
  owner   = "${var.owner}"
  ttl     = "${var.ttl}"
  token_for_nomad   = "${var.token_for_nomad}"
  vault_url         = "${var.vault_url}"
}

resource "null_resource" "start_sock_shop" {
  provisioner "remote-exec" {
    inline = [
      "sleep 180",
      "nomad run -address=http://${module.nomadconsul.primary_server_private_ips[0]}:4646 /home/ubuntu/sockshop.nomad"
    ]

    connection {
      host = "${module.nomadconsul.primary_server_public_ips[0]}"
      type = "ssh"
      agent = false
      user = "ubuntu"
      private_key = "${var.private_key_data}"
    }
  }
}

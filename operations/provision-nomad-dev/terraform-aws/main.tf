module "ssh_keypair_aws" {
  source = "github.com/hashicorp-modules/ssh-keypair-aws?ref=f-refactor"
}

module "network_aws" {
  source = "github.com/hashicorp-modules/network-aws?ref=f-refactor"
  # source = "../../../../../hashicorp-modules/network-aws"

  name              = "${var.name}"
  vpc_cidrs_public  = "${var.vpc_cidrs_public}"
  nat_count         = "${var.nat_count}"
  vpc_cidrs_private = "${var.vpc_cidrs_private}"
  bastion_count     = "${var.bastion_count}"
  tags              = "${var.network_tags}"
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

data "template_file" "nomad_user_data" {
  template = "${file("${path.module}/../../templates/install-nomad-systemd.sh.tpl")}"

  vars = {
    nomad_version = "${var.nomad_version}"
    nomad_url     = "${var.nomad_url}"
  }
}

module "nomad_aws" {
  source = "github.com/hashicorp-modules/nomad-aws?ref=f-refactor"
  # source = "../../../../../hashicorp-modules/nomad-aws"

  name         = "${var.name}" # Must match network_aws module name for Consul Auto Join to work
  vpc_id       = "${module.network_aws.vpc_id}"
  vpc_cidr     = "${module.network_aws.vpc_cidr_block}"
  subnet_ids   = "${module.network_aws.subnet_public_ids}" # Provision into public subnets to provide easier accessibility without a Bastion host
  public_ip    = "${var.nomad_public_ip}"
  count        = "${var.nomad_count}"
  image_id     = "${var.nomad_image_id != "" ? var.nomad_image_id : data.aws_ami.base.id}"
  ssh_key_name = "${element(module.ssh_keypair_aws.name, 0)}"
  user_data    = "${data.template_file.nomad_user_data.rendered}" # Custom user_data
  tags         = "${var.nomad_tags}"
}

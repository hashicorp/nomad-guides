terraform {
  required_version = ">= 0.11.10"
}

provider "aws" {
  region = "${var.region}"
}

provider "nomad" {
  address = "http://${element(module.nomadconsul.primary_server_public_ips, 0)}:4646"
  secret_id = "${module.nomadconsul.bootstrap_token}"
  #secret_id = "${var.bootstrap_token}"
}

module "network" {
  source = "modules/network"

  vpc_cidr          = "${var.vpc_cidr}"
  name_tag_prefix   = "${var.name_tag_prefix}"
  subnet_cidr       = "${var.subnet_cidr}"
  subnet_az         = "${var.subnet_az}"
}

module "nomadconsul" {
  source = "modules/nomadconsul"

  region            = "${var.region}"
  ami               = "${var.ami}"
  vpc_id            = "${module.network.vpc_id}"
  subnet_id         = "${module.network.subnet_id}"
  server_instance_type     = "${var.server_instance_type}"
  client_instance_type     = "${var.client_instance_type}"
  key_name          = "${var.key_name}"
  server_count      = "${var.server_count}"
  client_count      = "${var.client_count}"
  name_tag_prefix   = "${var.name_tag_prefix}"
  cluster_tag_value = "${var.cluster_tag_value}"
  owner   = "${var.owner}"
  ttl     = "${var.ttl}"
  private_key_data = "${var.private_key_data}"
}

# Nomad namespace: dev
resource "nomad_namespace" "dev" {
  name = "dev"
  description = "Shared development environment."
  depends_on = ["module.nomadconsul", "nomad_quota_specification.dev"]
}

# Nomad namespace: qa
resource "nomad_namespace" "qa" {
  name = "qa"
  description = "Shared QA environment."
  depends_on = ["module.nomadconsul", "nomad_quota_specification.qa"]
}

# Nomad ACL policy: anonymous
resource "nomad_acl_policy" "anonymous" {
  name = "anonymous"
  description = "restricted access for users without ACL tokens"
  rules_hcl = "${file("${path.module}/acls/anonymous.hcl")}"
  depends_on = ["module.nomadconsul"]
}

# Nomad ACL policy: dev
resource "nomad_acl_policy" "dev" {
  name = "dev"
  description = "access for users with dev ACL tokens"
  rules_hcl = "${file("${path.module}/acls/dev.hcl")}"
  depends_on = ["module.nomadconsul"]
}

# Nomad ACL policy: qa
resource "nomad_acl_policy" "qa" {
  name = "qa"
  description = "access for users with qa ACL tokens"
  rules_hcl = "${file("${path.module}/acls/qa.hcl")}"
  depends_on = ["module.nomadconsul"]
}

# Nomad ACL token: alice (dev)
resource "nomad_acl_token" "alice" {
  name = "alice"
  type = "client"
  policies = ["dev"]
  depends_on = ["module.nomadconsul", "module.network"]
}

# Nomad ACL token: bob (qa)
resource "nomad_acl_token" "bob" {
  name = "bob"
  type = "client"
  policies = ["qa"]
  depends_on = ["module.nomadconsul", "module.network"]
}

# Nomad quota: default
resource "nomad_quota_specification" "default" {
  name = "default"
  description = "default quota"
  limits {
    region = "global"
    region_limit {
      cpu = 4600
      memory_mb = 4100
    }
  }
  depends_on = ["module.nomadconsul"]
}


# Nomad quota: dev
resource "nomad_quota_specification" "dev" {
  name = "dev"
  description = "dev quota"
  limits {
    region = "global"
    region_limit {
      cpu = 4600
      memory_mb = 4100
    }
  }
  depends_on = ["module.nomadconsul"]
}

# Nomad quota: qa
resource "nomad_quota_specification" "qa" {
  name = "qa"
  description = "dev quota"
  limits {
    region = "global"
    region_limit {
      cpu = 4600
      memory_mb = 4100
    }
  }
  depends_on = ["module.nomadconsul"]
}

resource "null_resource" "attach_quotas" {
  provisioner "remote-exec" {
    inline = [
    "nomad namespace apply -quota ${nomad_quota_specification.default.name} -token=${module.nomadconsul.bootstrap_token} -address=http://${module.nomadconsul.primary_server_private_ips[0]}:4646 default",
    "nomad namespace apply -quota ${nomad_quota_specification.dev.name} -token=${module.nomadconsul.bootstrap_token} -address=http://${module.nomadconsul.primary_server_private_ips[0]}:4646 ${nomad_namespace.dev.name}",
    "nomad namespace apply -quota ${nomad_quota_specification.qa.name} -token=${module.nomadconsul.bootstrap_token} -address=http://${module.nomadconsul.primary_server_private_ips[0]}:4646 ${nomad_namespace.qa.name}",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo '{\"Name\":\"fake\",\"Limits\":[{\"Region\":\"global\",\"RegionLimit\": {\"CPU\":2500,\"MemoryMB\":1000}}]}' > ~/fake.hcl",
      "nomad quota apply -token=${var.bootstrap_token} -address=http://${module.nomadconsul.primary_server_private_ips[0]}:4646 -json ~/fake.hcl",
      "nomad namespace apply -token=${var.bootstrap_token} -address=http://${module.nomadconsul.primary_server_private_ips[0]}:4646 -quota fake default",
    ]
    when = "destroy"
  }

  connection {
    host = "${module.nomadconsul.primary_server_public_ips[0]}"
    type = "ssh"
    agent = false
    user = "ubuntu"
    private_key = "${var.private_key_data}"
  }

  triggers {
      uuid = "${uuid()}"
  }

  depends_on = ["module.nomadconsul", "nomad_quota_specification.default"]

}

# Nomad Sentinel policy: allow Docker and Java Drivers
resource "nomad_sentinel_policy" "docker_or_java" {
  name = "allow-docker-or-java-driver"
  description = "Only allow the Docker and Java drivers"
  policy = "${file("${path.module}/sentinel/allow-docker-and-java-drivers.sentinel")}"
  scope = "submit-job"
  enforcement_level = "hard-mandatory"
  depends_on = ["module.nomadconsul"]
}

# Nomad Sentinel policy: Prevent Docker host network mode
resource "nomad_sentinel_policy" "prevent_host_network" {
  name = "prevent-docker-host-network"
  description = "Prevent Docker containers running with host network mode"
  policy = "${file("${path.module}/sentinel/prevent-docker-host-network.sentinel")}"
  scope = "submit-job"
  enforcement_level = "soft-mandatory"
  depends_on = ["module.nomadconsul"]
}

# Nomad Sentinel policy: Restrict Docker images
resource "nomad_sentinel_policy" "restrict-docker-images" {
  name = "restrict-docker-images"
  description = "Restrict allowed Docker images"
  policy = "${file("${path.module}/sentinel/restrict-docker-images.sentinel")}"
  scope = "submit-job"
  enforcement_level = "soft-mandatory"
  depends_on = ["module.nomadconsul"]
}

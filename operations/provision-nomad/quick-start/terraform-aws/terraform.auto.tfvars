# ---------------------------------------------------------------------------------------------------------------------
# General Variables
# ---------------------------------------------------------------------------------------------------------------------
# name      = "nomad-quick-start"
# ami_owner = "099720109477" # Base image owner, defaults to RHEL
# ami_name  = "*ubuntu-xenial-16.04-amd64-server-*" # Base image name, defaults to RHEL

# ---------------------------------------------------------------------------------------------------------------------
# Network Variables
# ---------------------------------------------------------------------------------------------------------------------
# vpc_cidr          = "172.19.0.0/16"
# vpc_cidrs_public  = ["172.19.0.0/20", "172.19.16.0/20", "172.19.32.0/20",]
# vpc_cidrs_private = ["172.19.48.0/20", "172.19.64.0/20", "172.19.80.0/20",]

# nat_count        = 1 # Number of NAT gateways to provision across public subnets, defaults to public subnet count.
# bastion_servers  = 1 # Number of bastion hosts to provision across public subnets, defaults to public subnet count.
# bastion_instance = "t2.micro"
# bastion_image_id = "" # AMI ID override, defaults to base RHEL AMI

# network_tags = {"owner" = "hashicorp", "TTL" = "24"}

# ---------------------------------------------------------------------------------------------------------------------
# Consul Variables
# ---------------------------------------------------------------------------------------------------------------------
# consul_servers  = 1 # Number of Consul servers, defaults to subnet count
# consul_instance = "t2.micro"
# consul_version  = "1.0.6" # Consul Version for runtime install, defaults to 1.0.6
# consul_url      = "" # Consul Enterprise download URL for runtime install, defaults to Consul OSS
# consul_image_id = "" # AMI ID override, defaults to base RHEL AMI

# If 'consul_public' is true, assign a public IP, open port 22 for public access, & provision into
# public subnets to provide easier accessibility without a Bastion host - DO NOT DO THIS IN PROD
# consul_public = true

# consul_server_config_override = <<EOF
# {
#   "log_level": "DEBUG",
#   "disable_remote_exec": false
# }
# EOF

# consul_client_config_override = <<EOF
# {
#   "log_level": "DEBUG",
#   "disable_remote_exec": false
# }
# EOF

# consul_tags = {"owner" = "hashicorp", "TTL" = "24"}

# consul_tags_list = [
#   {"key" = "owner", "value" = "hashicorp", "propagate_at_launch" = true},
#   {"key" = "TTL", "value" = "24", "propagate_at_launch" = true}
# ]

# ---------------------------------------------------------------------------------------------------------------------
# Vault Variables
# ---------------------------------------------------------------------------------------------------------------------
# vault_provision = true # Provision Vault
# vault_servers   = 1 # Number of Vault servers, defaults to subnet count
# vault_instance  = "t2.micro"
# vault_version   = "0.10.0" # Vault Version for runtime install, defaults to 0.10.0
# vault_url       = "" # Vault Enterprise download URL for runtime install, defaults to Vault OSS
# vault_image_id  = "" # AMI ID override, defaults to base RHEL AMI

# If 'vault_public' is true, assign a public IP, open port 22 for public access, & provision into
# public subnets to provide easier accessibility without a Bastion host - DO NOT DO THIS IN PROD
# vault_public = true

# vault_server_config_override = <<EOF
# # These values will override the defaults
# cluster_name = "dc1"
# EOF

# vault_tags = {"owner" = "hashicorp", "TTL" = "24"}

# vault_tags_list = [
#   {"key" = "owner", "value" = "hashicorp", "propagate_at_launch" = true},
#   {"key" = "TTL", "value" = "24", "propagate_at_launch" = true}
# ]

# ---------------------------------------------------------------------------------------------------------------------
# Nomad Variables
# ---------------------------------------------------------------------------------------------------------------------
# nomad_servers  = 3 # Number of Nomad servers, defaults to subnet count
# nomad_clients  = 3 # Nomad clients count
# nomad_instance = "t2.micro"
# nomad_version  = "0.8.0" # Nomad Version for runtime install, defaults to 0.8.0
# nomad_url      = "" # Nomad Enterprise download URL for runtime install, defaults to Nomad OSS
# nomad_image_id = "" # AMI ID override, defaults to base RHEL AMI

# If 'nomad_public' is true, assign a public IP, open port 22 for public access, & provision into
# public subnets to provide easier accessibility without a Bastion host - DO NOT DO THIS IN PROD
# nomad_public = true

# nomad_server_config_override = <<EOF
# # These values will override the defaults
# datacenter   = "dc1"
# log_level    = "DEBUG"
# enable_debug = true
#
# server {
#   heartbeat_grace = "30s"
# }
# EOF

# nomad_client_config_override = <<EOF
# # These values will override the defaults
# datacenter   = "dc1"
# log_level    = "DEBUG"
# enable_debug = true
#
# client {
#   node_class      = "fizz"
#   client_max_port = 15000
#
#   options {
#     "docker.cleanup.image"   = "0"
#     "driver.raw_exec.enable" = "1"
#   }
# }
# EOF

# nomad_client_docker_install = true # Install Docker on Nomad clients
# nomad_client_java_install   = false # Install Java on Nomad clients

# nomad_tags = {"owner" = "hashicorp", "TTL" = "24"}

# nomad_tags_list = [
#   {"key" = "owner", "value" = "hashicorp", "propagate_at_launch" = true},
#   {"key" = "TTL", "value" = "24", "propagate_at_launch" = true}
# ]

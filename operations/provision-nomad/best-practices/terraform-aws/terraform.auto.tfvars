# ---------------------------------------------------------------------------------------------------------------------
# General Variables
# ---------------------------------------------------------------------------------------------------------------------
# name           = "nomad-best-practices"
# download_certs = true

# ---------------------------------------------------------------------------------------------------------------------
# Network Variables
# ---------------------------------------------------------------------------------------------------------------------
# vpc_cidr          = "172.19.0.0/16"
# vpc_cidrs_public  = ["172.19.0.0/20", "172.19.16.0/20", "172.19.32.0/20",]
# vpc_cidrs_private = ["172.19.48.0/20", "172.19.64.0/20", "172.19.80.0/20",]

# nat_count              = 1 # Number of NAT gateways to provision across public subnets, defaults to public subnet count.
# bastion_servers        = 1 # Number of bastion hosts to provision across public subnets, defaults to public subnet count.
# bastion_instance       = "t2.micro"
# bastion_release        = "0.1.0" # Release version tag (e.g. 0.1.0, 0.1.0-rc1, 0.1.0-beta1, 0.1.0-dev1)
# bastion_consul_version = "1.2.0" # Consul version tag (e.g. 1.2.0 or 1.2.0-ent) - https://releases.hashicorp.com/consul/
# bastion_vault_version  = "0.10.3" # Vault version tag (e.g. 0.10.3 or 0.10.3-ent) - https://releases.hashicorp.com/vault/
# bastion_nomad_version  = "0.8.4" # Nomad version tag (e.g. 0.8.4 or 0.8.4-ent) - https://releases.hashicorp.com/nomad/
# bastion_os             = "Ubuntu" # OS (e.g. RHEL, Ubuntu), defaults to RHEL
# bastion_os_version     = "16.04" # OS Version (e.g. 7.3 for RHEL, 16.04 for Ubuntu), defaults to 7.3
# bastion_image_id       = "" # AMI ID override, defaults to base RHEL AMI

# network_tags = {"owner" = "hashicorp", "TTL" = "24"}

# ---------------------------------------------------------------------------------------------------------------------
# Consul Variables
# ---------------------------------------------------------------------------------------------------------------------
# consul_servers    = 3 # Number of Consul servers to provision across public subnets, defaults to public subnet count.
# consul_instance   = "t2.micro"
# consul_release    = "0.1.0" # Release version tag (e.g. 0.1.0, 0.1.0-rc1, 0.1.0-beta1, 0.1.0-dev1)
# consul_version    = "1.2.0" # Consul version tag (e.g. 1.2.0 or 1.2.0-ent) - https://releases.hashicorp.com/consul/
# consul_os         = "RHEL" # OS (e.g. RHEL, Ubuntu)
# consul_os_version = "7.3" # OS Version (e.g. 7.3 for RHEL, 16.04 for Ubuntu)
# consul_image_id   = "" # AMI ID override, defaults to base RHEL AMI

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
# vault_provision  = true # Provision Vault
# vault_servers    = 3 # Number of Vault servers, defaults to public count
# vault_instance   = "t2.micro"
# vault_release    = "0.1.0" # Release version tag (e.g. 0.1.0, 0.1.0-rc1, 0.1.0-beta1, 0.1.0-dev1)
# vault_version    = "0.10.3" #  Version tag (e.g. 0.10.3 or 0.10.3-ent) - https://releases.hashicorp.com/vault/
# vault_os         = "RHEL" # OS (e.g. RHEL, Ubuntu)
# vault_os_version = "7.3" # OS Version (e.g. 7.3 for RHEL, 16.04 for Ubuntu)
# vault_image_id   = "" # AMI ID override, defaults to base RHEL AMI

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
# nomad_servers    = 3 # Number of Nomad server nodes to provision across public subnets, defaults to public subnet count.
# nomad_clients    = 1 # Number of Nomad client nodes to provision across public subnets, defaults to public subnet count.
# nomad_instance   = "t2.micro"
# nomad_release    = "0.1.0" # Release version tag (e.g. 0.1.0, 0.1.0-rc1, 0.1.0-beta1, 0.1.0-dev1)
# nomad_version    = "0.8.4" # Nomad version tag (e.g. 0.8.4 or 0.8.4-ent) - https://releases.hashicorp.com/nomad/
# nomad_os         = "RHEL" # OS (e.g. RHEL, Ubuntu)
# nomad_os_version = "7.3" # OS Version (e.g. 7.3 for RHEL, 16.04 for Ubuntu)
# nomad_image_id   = "" # AMI ID override, defaults to base RHEL AMI

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

# nomad_client_docker_install = false # Install Docker on Nomad clients
# nomad_client_java_install   = false # Install Java on Nomad clients

# nomad_tags = {"owner" = "hashicorp", "TTL" = "24"}

# nomad_tags_list = [
#   {"key" = "owner", "value" = "hashicorp", "propagate_at_launch" = true},
#   {"key" = "TTL", "value" = "24", "propagate_at_launch" = true}
# ]

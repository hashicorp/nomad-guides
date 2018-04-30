# ---------------------------------------------------------------------------------------------------------------------
# General Variables
# ---------------------------------------------------------------------------------------------------------------------
# name      = "nomad-dev"
# ami_owner = "099720109477" # Base image owner, defaults to RHEL
# ami_name  = "*ubuntu-xenial-16.04-amd64-server-*" # Base image name, defaults to RHEL

# ---------------------------------------------------------------------------------------------------------------------
# Network Variables
# ---------------------------------------------------------------------------------------------------------------------
# vpc_cidr          = "172.19.0.0/16"
# vpc_cidrs_public  = ["172.19.0.0/20", "172.19.16.0/20", "172.19.32.0/20",]
# vpc_cidrs_private = ["172.19.48.0/20", "172.19.64.0/20", "172.19.80.0/20",]

# nat_count        = 1 # Defaults to 1
# bastion_servers  = 0 # Defaults to 0
# bastion_image_id = "" # AMI ID override, defaults to base RHEL AMI

# network_tags = {"owner" = "hashicorp", "TTL" = "24"}

# ---------------------------------------------------------------------------------------------------------------------
# Consul Variables
# ---------------------------------------------------------------------------------------------------------------------
# consul_install = true # Install Consul
# consul_version = "1.0.6" # Consul Version for runtime install, defaults to 1.0.6
# consul_url     = "" # Consul Enterprise download URL for runtime install, defaults to Consul OSS

# consul_config_override = <<EOF
# {
#   "log_level": "DEBUG",
#   "disable_remote_exec": false
# }
# EOF

# ---------------------------------------------------------------------------------------------------------------------
# Vault Variables
# ---------------------------------------------------------------------------------------------------------------------
# vault_install = true # Install Vault
# vault_version = "0.10.0" # Vault Version for runtime install, defaults to 0.10.0
# vault_url     = "" # Vault Enterprise download URL for runtime install, defaults to Vault OSS

# If Vault config is overridden, Vault will no longer run in -dev mode
# vault_config_override = <<EOF
# # These values will override the defaults
# cluster_name = "dc1"
# ui           = true
#
# storage "file_transactional" {
#   path          = "/opt/vault/data"
#   redirect_addr = "http://127.0.0.1:8200"
# }
#
# listener "tcp" {
#   address     = "0.0.0.0:8200"
#   tls_disable = "true"
# }
# EOF

# ---------------------------------------------------------------------------------------------------------------------
# Nomad Variables
# ---------------------------------------------------------------------------------------------------------------------
# nomad_servers  = 3
# nomad_instance = "t2.micro"
# nomad_version  = "0.8.0" # Nomad Version for runtime install, defaults to 0.8.0
# nomad_url      = "" # Nomad Enterprise download URL for runtime install, defaults to Nomad OSS
# nomad_image_id = "" # AMI ID override, defaults to base RHEL AMI

# If 'nomad_public' is true, assign a public IP, open port 22 for public access, & provision into public subnets
# to provide easier accessibility without a Bastion host - DO NOT DO THIS IN PROD
# nomad_public = true

# nomad_config_override = <<EOF
# datacenter   = "dc1"
# log_level    = "DEBUG"
# enable_debug = true
#
# server {
#   heartbeat_grace = "30s"
# }
#
# client {
#   node_class      = "foo"
#   client_max_port = 15000
#
#   options {
#     "docker.cleanup.image" = "0"
#   }
# }
#
# consul {
#   address        = "127.0.0.1:8500"
#   auto_advertise = true
#
#   server_service_name = "nomad"
#   server_auto_join    = true
#
#   client_service_name = "nomad-client"
#   client_auto_join    = true
# }
#
# vault {
#   enabled = true # Set to false if Vault is not running in -dev mode using the in-mem storage backend
#   address = "http://127.0.0.1:8200"
#
#   # Only set "token" when Vault is running in -dev mode using the in-mem storage backend,
#   # if not, comment this out and set the VAULT_TOKEN env var for Nomad in /etc/nomad.d/nomad.conf
#   token = "root"
#
#   tls_skip_verify = true
# }
# EOF

# nomad_docker_install = false # Install Docker on host
# nomad_java_install   = false # Install Java on host

# nomad_tags = {"owner" = "hashicorp", "TTL" = "24"}

# nomad_tags_list = [
#   {"key" = "owner", "value" = "hashicorp", "propagate_at_launch" = true},
#   {"key" = "TTL", "value" = "24", "propagate_at_launch" = true}
# ]

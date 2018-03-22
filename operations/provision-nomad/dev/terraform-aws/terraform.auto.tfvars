name              = "nomad-dev"
vpc_cidrs_public  = ["10.139.1.0/24",]
vpc_cidrs_private = ["10.139.11.0/24",]
nat_count         = "1"
bastion_count     = "0"
nomad_public_ip   = "true"
nomad_count       = "1"
# ami_owner         = "099720109477" # Base image owner, defaults to RHEL
# ami_name          = "*ubuntu-xenial-16.04-amd64-server-*" # Base image name, defaults to RHEL
# nomad_version     = "0.7.1" # Nomad Version for runtime install, defaults to 0.7.1
# nomad_url         = "" # Nomad Enterprise download URL for runtime install, defaults to Nomad OSS
# nomad_image_id    = "" # AMI ID override, defaults to base RHEL AMI

# install_docker     = "true" # Install Docker on Nomad clients
# install_oracle_jdk = "true" # Install Oracle JDK on Nomad clients

# Example tags
# network_tags = {"owner" = "hashicorp", "TTL" = "24"}
#
# consul_tags = [
#   {"key" = "owner", "value" = "hashicorp", "propagate_at_launch" = true},
#   {"key" = "TTL", "value" = "24", "propagate_at_launch" = true}
# ]
#
# nomad_tags = [
#   {"key" = "owner", "value" = "hashicorp", "propagate_at_launch" = true},
#   {"key" = "TTL", "value" = "24", "propagate_at_launch" = true}
# ]

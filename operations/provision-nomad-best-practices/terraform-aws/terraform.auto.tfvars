# General
name = "nomad-best-practices"

# Network module
vpc_cidr                = "172.19.0.0/16"
vpc_cidrs_public        = ["172.19.0.0/20", "172.19.16.0/20", "172.19.32.0/20",]
nat_count               = "1" # Number of NAT gateways to provision across public subnets, defaults to public subnet count.
vpc_cidrs_private       = ["172.19.48.0/20", "172.19.64.0/20", "172.19.80.0/20",]
bastion_release_version = "0.1.0-dev1" # Release version tag (e.g. 0.1.0, 0.1.0-rc1, 0.1.0-beta1, 0.1.0-dev1)
bastion_consul_version  = "0.9.2" # Consul version tag (e.g. 0.9.2 or 0.9.2-ent) - https://releases.hashicorp.com/consul/
bastion_nomad_version   = "0.6.2" # Nomad version tag (e.g. 0.6.2 or 0.6.2-ent) - https://releases.hashicorp.com/nomad/
bastion_os              = "RHEL" # OS (e.g. RHEL, Ubuntu)
bastion_os_version      = "7.3" # OS Version (e.g. 7.3 for RHEL, 16.04 for Ubuntu)
bastion_count           = "1" # Number of bastion hosts to provision across public subnets, defaults to public subnet count.
bastion_instance_type   = "t2.small"

# Consul module
consul_release_version = "0.1.0-dev1" # Release version tag (e.g. 0.1.0, 0.1.0-rc1, 0.1.0-beta1, 0.1.0-dev1)
consul_version         = "0.9.2" # Consul version tag (e.g. 0.9.2 or 0.9.2-ent) - https://releases.hashicorp.com/consul/
consul_os              = "Ubuntu" # OS (e.g. RHEL, Ubuntu)
consul_os_version      = "16.04" # OS Version (e.g. 7.3 for RHEL, 16.04 for Ubuntu)
consul_count           = "3" # Number of Consul nodes to provision across public subnets, defaults to public subnet count.
consul_instance_type   = "t2.small"

# Nomad module
nomad_release_version = "0.1.0-dev1" # Release version tag (e.g. 0.1.0, 0.1.0-rc1, 0.1.0-beta1, 0.1.0-dev1)
nomad_version         = "0.6.2" # Nomad version tag (e.g. 0.6.2 or 0.6.2-ent) - https://releases.hashicorp.com/nomad/
nomad_os              = "RHEL" # OS (e.g. RHEL, Ubuntu)
nomad_os_version      = "7.3" # OS Version (e.g. 7.3 for RHEL, 16.04 for Ubuntu)
nomad_servers         = "3" # Number of Nomad server nodes to provision across public subnets, defaults to public subnet count.
nomad_clients         = "3" # Number of Nomad client nodes to provision across public subnets, defaults to public subnet count.
nomad_instance_type   = "t2.small"

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

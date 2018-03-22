name = "nomad-quick-start"

# ami_owner = "099720109477" # Base image owner, defaults to RHEL
# ami_name  = "*ubuntu-xenial-16.04-amd64-server-*" # Base image name, defaults to RHEL

# consul_version  = "0.9.2" # Consul Version for runtime install, defaults to 0.9.2
# consul_url      = "" # Consul Enterprise download URL for runtime install, defaults to Consul OSS
# consul_image_id = "" # AMI ID override, defaults to base RHEL AMI

# nomad_version  = "0.6.2" # Nomad Version for runtime install, defaults to 0.8.1
# nomad_url      = "" # Nomad Enterprise download URL for runtime install, defaults to Nomad OSS
# nomad_image_id = "" # AMI ID override, defaults to base RHEL AMI
# nomad_servers  = "3" # Nomad server count
# nomad_clients  = "1" # Nomad clients count

# Additional Consul server config
consul_server_config = <<EOF
{
  "log_level": "DEBUG"
}
EOF

# Additional Consul client config
consul_client_config = <<EOF
{
  "log_level": "DEBUG"
}
EOF

nomad_server_config = <<EOF
# Additional Nomad server config
log_level = "DEBUG"
EOF

nomad_server_stanza = <<EOF
  # Additional Nomad Server stanza config
  heartbeat_grace = "30s"
EOF

nomad_server_consul_stanza = <<EOF
  # Additional Nomad Server Consul stanza config
  client_service_name = "nomad-client"
  server_service_name = "nomad-server"
EOF

nomad_client_config = <<EOF
# Additional Nomad client config
log_level = "DEBUG"
EOF

nomad_client_stanza = <<EOF
  # Additional Nomad Client stanza config
  node_class = "foo"
  client_max_port = 15000

  options {
    "docker.cleanup.image"   = "0"
    "driver.raw_exec.enable" = "1"
  }
EOF

nomad_client_consul_stanza = <<EOF
  # Additional Nomad Client Consul stanza config
  client_service_name = "nomad-client"
  server_service_name = "nomad-server"
EOF

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

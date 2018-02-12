#!/bin/bash

echo "[---Begin quick-start-nomad-systemd.sh---]"

echo "Set variables"
LOCAL_IPV4=$(curl -s ${local_ip_url})
CONSUL_CONFIG_FILE=/etc/consul.d/consul-client.json
NOMAD_CONFIG_FILE=/etc/nomad.d/nomad-server.hcl

echo "Configure Nomad Consul client"
cat <<CONFIG | sudo tee $CONSUL_CONFIG_FILE
{
  "datacenter": "${name}",
  "advertise_addr": "$LOCAL_IPV4",
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "log_level": "INFO",
  "ui": true,
  "retry_join": ["provider=${provider} tag_key=Consul-Auto-Join tag_value=${name}"]
}
CONFIG

echo "Update Consul configuration file permissions"
sudo chown consul:consul $CONSUL_CONFIG_FILE

echo "Don't start Consul in -dev mode"
cat <<SWITCHES | sudo tee /etc/consul.d/consul.conf
SWITCHES

echo "Restart Consul"
sudo systemctl restart consul

echo "Configure Nomad server"
cat <<CONFIG | sudo tee $NOMAD_CONFIG_FILE
data_dir  = "/opt/nomad/data"
log_level = "INFO"

server {
  enabled          = true
  bootstrap_expect = ${nomad_bootstrap}
  heartbeat_grace  = "30s"
}

client {
  enabled         = true
  client_max_port = 15000

  options {
    "docker.cleanup.image"   = "0"
    "driver.raw_exec.enable" = "1"
  }
}

consul {
  address        = "127.0.0.1:8500"
  auto_advertise = true

  client_service_name = "nomad-client"
  client_auto_join    = true

  server_service_name = "nomad-server"
  server_auto_join    = true
}
CONFIG

echo "Update Nomad configuration file permissions"
sudo chown nomad:nomad $NOMAD_CONFIG_FILE

echo "Configure Nomad environment variables to point Nomad client CLI to local Nomad cluster and skip TLS verification on login"
cat <<ENVVARS | sudo tee /etc/profile.d/nomad.sh
export NOMAD_ADDR="http://127.0.0.1:4646"
export NOMAD_SKIP_VERIFY="true"
ENVVARS

echo "Don't start Nomad in -dev mode"
cat <<SWITCHES | sudo tee /etc/nomad.d/nomad.conf
SWITCHES

echo "Restart Nomad"
sudo systemctl restart nomad

echo "[---quick-start-nomad-systemd.sh Complete---]"

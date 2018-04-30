#!/bin/bash

echo "[---Begin quick-start-bastion-systemd.sh---]"

echo "Set variables"
LOCAL_IPV4=$(curl -s ${local_ip_url})
CONSUL_CONFIG_FILE=/etc/consul.d/consul-client.json
CONSUL_CUSTOM_CONFIG_FILE=/etc/consul.d/consul-client-custom.json

echo "Configure Bastion Consul client"
cat <<CONFIG | sudo tee $CONSUL_CONFIG_FILE
{
  "datacenter": "${name}",
  "advertise_addr": "$LOCAL_IPV4",
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "ui": true,
  "retry_join": ["provider=${provider} tag_key=Consul-Auto-Join tag_value=${name}"]
}
CONFIG

if [[ ! -z "${consul_config}" ]]; then
  echo "Add custom Bastion Consul client config"
  cat <<CONFIG | sudo tee $CONSUL_CUSTOM_CONFIG_FILE
${consul_config}
CONFIG
fi

echo "Update Consul configuration file permissions"
sudo chown consul:consul $CONSUL_CONFIG_FILE $CONSUL_CUSTOM_CONFIG_FILE

echo "Don't start Consul in -dev mode"
cat <<SWITCHES | sudo tee /etc/consul.d/consul.conf
SWITCHES

echo "Restart Consul"
sudo systemctl restart consul

echo "Configure Nomad environment variables to point Nomad client CLI to local Nomad cluster and skip TLS verification on login"
cat <<ENVVARS | sudo tee /etc/profile.d/nomad.sh
export NOMAD_ADDR="http://nomad-server.service.consul:4646"
export NOMAD_SKIP_VERIFY="true"
ENVVARS

echo "Don't start Nomad in -dev mode"
cat <<SWITCHES | sudo tee /etc/nomad.d/nomad.conf
SWITCHES

echo "Stop Nomad now that the CLI is pointing to a live Nomad cluster"
sudo systemctl stop nomad

echo "[---quick-start-bastion-systemd.sh Complete---]"

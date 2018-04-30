#!/bin/bash

echo "[---Begin quick-start-nomad-client-systemd.sh---]"

echo "Set variables"
NODE_NAME=$(hostname)
LOCAL_IPV4=$(curl -s ${local_ip_url})
CONSUL_CONFIG_FILE=/etc/consul.d/default.json
CONSUL_CONFIG_OVERRIDE_FILE=/etc/consul.d/z-override.json
NOMAD_CONFIG_FILE=/etc/nomad.d/default.hcl
NOMAD_CONFIG_OVERRIDE_FILE=/etc/nomad.d/z-override.hcl

echo "Configure Nomad Consul client"
cat <<CONFIG | sudo tee $CONSUL_CONFIG_FILE
{
  "datacenter": "${name}",
  "node_name": "$NODE_NAME",
  "data_dir": "/opt/consul/data",
  "log_level": "INFO",
  "advertise_addr": "$LOCAL_IPV4",
  "client_addr": "0.0.0.0",
  "ui": true,
  "retry_join": ["provider=${provider} tag_key=Consul-Auto-Join tag_value=${name}"]
}
CONFIG

echo "Update Consul configuration file permissions"
sudo chown consul:consul $CONSUL_CONFIG_FILE

if [ ${consul_override} == true ] || [ ${consul_override} == 1 ]; then
  echo "Add custom Consul client override config"
  cat <<CONFIG | sudo tee $CONSUL_CONFIG_OVERRIDE_FILE
${consul_config}
CONFIG

  echo "Update Consul configuration override file permissions"
  sudo chown consul:consul $CONSUL_CONFIG_OVERRIDE_FILE
fi

echo "Don't start Consul in -dev mode"
cat <<ENVVARS | sudo tee /etc/consul.d/consul.conf
CONSUL_HTTP_ADDR=127.0.0.1:8500
CONSUL_HTTP_SSL=false
CONSUL_HTTP_SSL_VERIFY=false
ENVVARS

echo "Configure Consul environment variables for HTTP API requests on login"
cat <<PROFILE | sudo tee /etc/profile.d/consul.sh
export CONSUL_ADDR=http://127.0.0.1:8500
PROFILE

echo "Restart Consul"
sudo systemctl restart consul

echo "Configure Nomad client"
cat <<CONFIG | sudo tee $NOMAD_CONFIG_FILE
# https://www.nomadproject.io/docs/agent/configuration/index.html
region    = "global"
name      = "$NODE_NAME"
log_level = "INFO"
data_dir  = "/opt/nomad/data"
bind_addr = "0.0.0.0"

# https://www.nomadproject.io/docs/agent/configuration/index.html#advertise
advertise {
  http = "$LOCAL_IPV4:4646"
  rpc  = "$LOCAL_IPV4:4647"
  serf = "$LOCAL_IPV4:4648"
}

# https://www.nomadproject.io/docs/agent/configuration/client.html
client {
  enabled = true

  options {
    "driver.raw_exec.enable" = "1"
  }
}

# https://www.nomadproject.io/docs/agent/configuration/consul.html
consul {
  address        = "127.0.0.1:8500"
  auto_advertise = true

  server_service_name = "nomad"
  server_auto_join    = true

  client_service_name = "nomad-client"
  client_auto_join    = true
}
CONFIG

echo "Update Nomad configuration file permissions"
sudo chown root:root $NOMAD_CONFIG_FILE

if [ ${nomad_override} == true ] || [ ${nomad_override} == 1 ]; then
  echo "Add custom Nomad client override config"
  cat <<CONFIG | sudo tee $NOMAD_CONFIG_OVERRIDE_FILE
${nomad_config}
CONFIG

  echo "Update Nomad configuration override file permissions"
  sudo chown root:root $NOMAD_CONFIG_OVERRIDE_FILE
fi

echo "Configure Nomad environment variables to point Nomad client CLI to local Nomad cluster and skip TLS verification on login"
cat <<PROFILE | sudo tee /etc/profile.d/nomad.sh
export NOMAD_ADDR=http://127.0.0.1:4646
export NOMAD_SKIP_VERIFY=true
PROFILE

echo "Don't start Nomad in -dev mode"
echo '' | sudo tee /etc/nomad.d/nomad.conf

echo "Restart Nomad"
sudo systemctl restart nomad

echo "[---quick-start-nomad-client-systemd.sh Complete---]"

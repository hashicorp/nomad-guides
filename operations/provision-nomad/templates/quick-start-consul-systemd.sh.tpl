#!/bin/bash

echo "[---Begin quick-start-consul-systemd.sh---]"

echo "Set variables"
LOCAL_IPV4=$(curl -s ${local_ip_url})
CONSUL_CONFIG_FILE=/etc/consul.d/consul-server.json
CONSUL_CUSTOM_CONFIG_FILE=/etc/consul.d/consul-server-custom.json

echo "Configure Consul server"
cat <<CONFIG | sudo tee $CONSUL_CONFIG_FILE
{
  "datacenter": "${name}",
  "advertise_addr": "$LOCAL_IPV4",
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "ui": true,
  "server": true,
  "bootstrap_expect": ${consul_bootstrap},
  "leave_on_terminate": true,
  "retry_join": ["provider=${provider} tag_key=Consul-Auto-Join tag_value=${name}"]
}
CONFIG

if [[ ! -z "${consul_config}" ]]; then
  echo "Add custom Consul server config"
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

echo "[---quick-start-consul-systemd.sh Complete---]"

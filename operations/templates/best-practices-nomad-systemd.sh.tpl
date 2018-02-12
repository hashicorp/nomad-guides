#!/bin/bash

echo "[---Begin best-practices-nomad-systemd.sh---]"

echo "Update resolv.conf"
sudo sed -i '1i nameserver 127.0.0.1\n' /etc/resolv.conf

echo "Set variables"
LOCAL_IPV4=$(curl -s ${local_ip_url})
CONSUL_TLS_FILE=/opt/consul/tls
CONSUL_CACERT_FILE="$CONSUL_TLS_FILE/ca.crt"
CONSUL_CLIENT_CERT_FILE="$CONSUL_TLS_FILE/consul.crt"
CONSUL_CLIENT_KEY_FILE="$CONSUL_TLS_FILE/consul.key"
CONSUL_CONFIG_FILE=/etc/consul.d/consul-client.json
NOMAD_TLS_FILE=/opt/nomad/tls
NOMAD_CACERT_FILE="$NOMAD_TLS_FILE/ca.crt"
NOMAD_CLIENT_CERT_FILE="$NOMAD_TLS_FILE/nomad.crt"
NOMAD_CLIENT_KEY_FILE="$NOMAD_TLS_FILE/nomad.key"
NOMAD_CONFIG_FILE=/etc/nomad.d/nomad-server.hcl

echo "Create TLS dir for Consul certs"
sudo mkdir -pm 0755 $CONSUL_TLS_FILE

echo "Write Consul CA certificate to $CONSUL_CACERT_FILE"
cat <<EOF | sudo tee $CONSUL_CACERT_FILE
${consul_ca_crt}
EOF

echo "Write Consul certificate to $CONSUL_CLIENT_CERT_FILE"
cat <<EOF | sudo tee $CONSUL_CLIENT_CERT_FILE
${consul_leaf_crt}
EOF

echo "Write Consul certificate key to $CONSUL_CLIENT_KEY_FILE"
cat <<EOF | sudo tee $CONSUL_CLIENT_KEY_FILE
${consul_leaf_key}
EOF

echo "Configure Nomad Consul client"
cat <<CONFIG | sudo tee $CONSUL_CONFIG_FILE
{
  "datacenter": "${name}",
  "advertise_addr": "$LOCAL_IPV4",
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "log_level": "INFO",
  "ui": true,
  "retry_join": ["provider=${provider} tag_key=Consul-Auto-Join tag_value=${name}"],
  "encrypt": "${consul_encrypt}",
  "ca_file": "$CONSUL_CACERT_FILE",
  "cert_file": "$CONSUL_CLIENT_CERT_FILE",
  "key_file": "$CONSUL_CLIENT_KEY_FILE",
  "verify_incoming": true,
  "verify_outgoing": true,
  "ports": { "https": 8080 }
}
CONFIG

echo "Update Consul configuration & certificates file owner"
sudo chown -R consul:consul $CONSUL_CONFIG_FILE $CONSUL_TLS_FILE

echo "Don't start Consul in -dev mode"
cat <<SWITCHES | sudo tee /etc/consul.d/consul.conf
SWITCHES

echo "Restart Consul"
sudo systemctl restart consul

echo "Create tls dir for Nomad certs"
sudo mkdir -pm 0755 $NOMAD_TLS_FILE

echo "Write Nomad CA certificate to $NOMAD_CACERT_FILE"
cat <<EOF | sudo tee $NOMAD_CACERT_FILE
${nomad_ca_crt}
EOF

echo "Write Nomad certificate to $NOMAD_CLIENT_CERT_FILE"
cat <<EOF | sudo tee $NOMAD_CLIENT_CERT_FILE
${nomad_leaf_crt}
EOF

echo "Write Nomad certificate key to $NOMAD_CLIENT_KEY_FILE"
cat <<EOF | sudo tee $NOMAD_CLIENT_KEY_FILE
${nomad_leaf_key}
EOF

echo "Configure Nomad server"
cat <<CONFIG | sudo tee $NOMAD_CONFIG_FILE
data_dir  = "/opt/nomad/data"
log_level = "INFO"
enable_debug = true

server {
  enabled          = true
  bootstrap_expect = ${nomad_bootstrap}
  heartbeat_grace  = "30s"
  encrypt          = "${nomad_encrypt}"
}

client {
  enabled         = true
  client_max_port = 15000

  options {
    "docker.cleanup.image"   = "0"
    "driver.raw_exec.enable" = "1"
  }
}

tls {
  http = true
  rpc  = true

  ca_file   = "$NOMAD_CACERT_FILE"
  cert_file = "$NOMAD_CLIENT_CERT_FILE"
  key_file  = "$NOMAD_CLIENT_KEY_FILE"

  verify_server_hostname = true
  verify_https_client    = true
}

consul {
  address        = "127.0.0.1:8500"
  auto_advertise = true

  client_service_name = "nomad-client"
  client_auto_join    = true

  server_service_name = "nomad-server"
  server_auto_join    = true

  verify_ssl = true
  ca_file    = "$CONSUL_CACERT_FILE"
  cert_file  = "$CONSUL_CLIENT_CERT_FILE"
  key_file   = "$CONSUL_CLIENT_KEY_FILE"
}
CONFIG

echo "Update Nomad configuration & certificates file owner"
sudo chown -R nomad:nomad $NOMAD_CONFIG_FILE $NOMAD_TLS_FILE

echo "Configure Nomad environment variables to point Nomad client CLI to remote Nomad cluster & set TLS certs on login"
cat <<ENVVARS | sudo tee /etc/profile.d/nomad.sh
export NOMAD_ADDR="https://127.0.0.1:4646"
export NOMAD_CACERT="$NOMAD_CACERT_FILE"
export NOMAD_CLIENT_CERT="$NOMAD_CLIENT_CERT_FILE"
export NOMAD_CLIENT_KEY="$NOMAD_CLIENT_KEY_FILE"
ENVVARS

echo "Don't start Nomad in -dev mode"
cat <<SWITCHES | sudo tee /etc/nomad.d/nomad.conf
SWITCHES

echo "Restart Nomad"
sudo systemctl restart nomad

echo "Restart Docker"
sudo systemctl restart docker

echo "[---best-practices-nomad-systemd.sh Complete---]"
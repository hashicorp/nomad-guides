#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

set -e
set -v
set -x

export VAULT_ADDR=http://127.0.0.1:8200
cget() { curl -sf "http://127.0.0.1:8500/v1/kv/service/vault/$1?raw"; }

if [ ! $(cget root-token) ]; then
  logger "$0 - Initializing Vault"
  
  curl \
    --silent \
    --request PUT \
    --data '{"secret_shares": 1, "secret_threshold": 1}' \
    ${VAULT_ADDR}/v1/sys/init | tee \
    >(jq -r .root_token > /tmp/root-token) \
    >(jq -r .keys[0] > /tmp/unseal-key)

  curl -sfX PUT 127.0.0.1:8500/v1/kv/service/vault/unseal-key -d $(cat /tmp/unseal-key)
  curl -sfX PUT 127.0.0.1:8500/v1/kv/service/vault/root-token -d $(cat /tmp/root-token)

  vault operator unseal $(cget unseal-key)
  
  export ROOT_TOKEN=$(cget root-token)

  echo "Remove master keys from disk"

else
  logger "$0 - Vault already initialized"
fi

logger "$0 - Unsealing Vault"
vault operator unseal $(cget unseal-key)

export ROOT_TOKEN=$(cget root-token)
vault auth $ROOT_TOKEN

#Create admin user
echo '
path "*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}' | vault policy-write vault-admin -
vault auth-enable userpass
vault write auth/userpass/users/vault password=vault policies=vault-admin

vault mount database
vault write database/config/mysql \
  plugin_name=mysql-legacy-database-plugin \
  connection_url="vaultadmin:vaultadminpassword@tcp(192.168.50.152:3306)/"  \
  allowed_roles="readonly"

vault write database/roles/readonly \
  db_name=mysql \
  creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
  default_ttl="30m" \
  max_ttl="24h"

vault mount mysql
vault write mysql/config/connection \
  connection_url="vaultadmin:vaultadminpassword@tcp(192.168.50.152:3306)/" 

vault write mysql/roles/app \
  sql="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" 

logger "$0 - Vault setup complete"

vault status

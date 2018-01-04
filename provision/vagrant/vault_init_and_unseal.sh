#!/bin/bash
set -e
set -v
set -x

export VAULT_ADDR=http://127.0.0.1:8200
cget() { curl -sf "http://127.0.0.1:8500/v1/kv/service/vault/$1?raw"; }

if [ ! $(cget root-token) ]; then
  logger "$0 - Initializing Vault"
  vault init -address=http://localhost:8200 | tee /tmp/vault.init > /dev/null

  # Store master keys in consul for operator to retrieve and remove
  COUNTER=1
  grep 'Unseal' /tmp/vault.init | awk '{print $4}' | for key in $(cat -); do
    curl -sfX PUT 127.0.0.1:8500/v1/kv/service/vault/unseal-key-$COUNTER -d $key
    COUNTER=$((COUNTER + 1))
  done

  export ROOT_TOKEN=$(grep 'Root' /tmp/vault.init | awk '{print $4}')
  curl -sfX PUT 127.0.0.1:8500/v1/kv/service/vault/root-token -d $ROOT_TOKEN

  echo "Remove master keys from disk"

else
  logger "$0 - Vault already initialized"
fi

logger "$0 - Unsealing Vault"
vault unseal $(cget unseal-key-1)
vault unseal $(cget unseal-key-2)
vault unseal $(cget unseal-key-3)

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
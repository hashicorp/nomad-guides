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

logger "$0 - Vault setup complete"

vault status

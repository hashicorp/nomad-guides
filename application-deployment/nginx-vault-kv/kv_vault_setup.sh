#!/bin/bash
# Copyright IBM Corp. 2017, 2026


consul kv get service/vault/root-token | vault auth -

vault write secret/test message='Live demos rock!!!'

cat << EOF > test.policy
path "secret/*" {
    capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

vault policy-write test test.policy

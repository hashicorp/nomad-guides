#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


consul kv get service/vault/root-token | vault auth -

vault write secret/test message='Live demos rock!!!'

cat << EOF > test.policy
path "secret/*" {
    capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

vault policy-write test test.policy

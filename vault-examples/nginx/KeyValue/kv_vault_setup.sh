#!/bin/bash

vault write secret/test message='Live demos rock!!!'

cat << EOF > test.policy
path "secret/*" {
    capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

vault policy-write test test.policy

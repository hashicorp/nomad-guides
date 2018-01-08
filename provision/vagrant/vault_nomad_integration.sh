#!/bin/bash
set -e
set -v
set -x

export VAULT_ADDR=http://127.0.0.1:8200
cget() { curl -sf "http://127.0.0.1:8500/v1/kv/service/vault/$1?raw"; }

if [ $(cget root-token) ]; then
  export ROOT_TOKEN=$(cget root-token)
else
  exit
fi

vault auth $ROOT_TOKEN

echo '
# Allow creating tokens under "nomad-cluster" token role. The token role name
# should be updated if "nomad-cluster" is not used.
path "auth/token/create/nomad-cluster" {
  capabilities = ["update"]
}
# Allow looking up "nomad-cluster" token role. The token role name should be
# updated if "nomad-cluster" is not used.
path "auth/token/roles/nomad-cluster" {
  capabilities = ["read"]
}
# Allow looking up the token passed to Nomad to validate # the token has the
# proper capabilities. This is provided by the "default" policy.
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
# Allow looking up incoming tokens to validate they have permissions to access
# the tokens they are requesting. This is only required if
# `allow_unauthenticated` is set to false.
path "auth/token/lookup" {
  capabilities = ["update"]
}
# Allow revoking tokens that should no longer exist. This allows revoking
# tokens for dead tasks.
path "auth/token/revoke-accessor" {
  capabilities = ["update"]
}
# Allow checking the capabilities of our own token. This is used to validate the
# token upon startup.
path "sys/capabilities-self" {
  capabilities = ["update"]
}
# Allow our own token to be renewed.
path "auth/token/renew-self" {
  capabilities = ["update"]
}' | vault policy-write nomad-server -

echo '
{
  "disallowed_policies": "nomad-server",
  "explicit_max_ttl": 0,
  "name": "nomad-cluster",
  "orphan": false,
  "period": 259200,
  "renewable": true
}' | vault write /auth/token/roles/nomad-cluster -

NOMAD_TOKEN=$(vault token-create -policy nomad-server -period 72h -orphan | awk 'FNR == 3 {print$2}')

curl -sfX PUT 127.0.0.1:8500/v1/kv/service/vault/nomad-token -d $NOMAD_TOKEN
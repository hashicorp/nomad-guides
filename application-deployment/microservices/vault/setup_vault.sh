#!/bin/bash

# Script to setup of Vault for the Nomad/Consul demo
echo "Before running this, you must export your"
echo "AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY keys"
echo "and your VAULT_ADDR and VAULT_TOKEN environment variables."

# Set up the Vault AWS Secrets Engine
echo "Setting up the AWS Secrets Engine"
echo "Enabling the AWS secrets engine at path aws-tf"
vault secrets enable -path=aws-tf aws
echo "Providing Vault with AWS keys that can create other keys"
vault write aws-tf/config/root access_key=$AWS_ACCESS_KEY_ID secret_key=$AWS_SECRET_ACCESS_KEY
echo "Configuring default and max leases on generated keys"
vault write aws-tf/config/lease lease=1h lease_max=24h
echo "Creating the AWS deploy role and assigning policy to it"
vault write aws-tf/roles/deploy policy=@aws-policy.json

# Create sockshop-read policy
vault policy write sockshop-read sockshop-read.hcl

# Write the cataloguedb and userdb passwords to Vault
vault write secret/sockshop/databases/cataloguedb pwd=dioe93kdo931
vault write secret/sockshop/databases/userdb pwd=wo39c5h2sl4r

# Setup Vault policy/role for Nomad
echo "Setting up Vault policy and role for Nomad"
echo "Writing nomad-server-policy.hcl to Vault"
vault policy write nomad-server nomad-server-policy.hcl
echo "Writing nomad-cluster-role.json to Vault"
vault write auth/token/roles/nomad-cluster @nomad-cluster-role.json

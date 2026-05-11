# Copyright IBM Corp. 2017, 2026

# Read Access to Sock Shop secrets
path "secret/sockshop/*" {
  capabilities = ["read"]
}

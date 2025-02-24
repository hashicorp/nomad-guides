# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Read Access to Sock Shop secrets
path "secret/sockshop/*" {
  capabilities = ["read"]
}

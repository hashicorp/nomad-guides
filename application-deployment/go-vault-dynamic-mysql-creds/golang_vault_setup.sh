#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


consul kv get service/vault/root-token | vault auth -

POLICY='path "database/creds/readonly" { capabilities = [ "read", "list" ] }'

echo $POLICY > policy-mysql.hcl

vault policy-write mysql policy-mysql.hcl

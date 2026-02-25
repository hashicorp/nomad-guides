# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "IP_Addresses" {
  sensitive = true
  value = <<CONFIGURATION

Client public IPs: ${join(", ", module.nomadconsul.client_public_ips[0])}
Client private IPs: ${join(", ", module.nomadconsul.client_private_ips[0])}
Server public IPs: ${join(", ", module.nomadconsul.primary_server_public_ips[0])}
Server private IPs: ${join(", ", module.nomadconsul.primary_server_private_ips[0])}

# `ssh -i "${var.key_name}.pem" ubuntu@$(module.nomadconsul.primary_server_public_ips[0])`

The Consul UI can be accessed at http://$(module.nomadconsul.primary_server_public_ips[0]):8500/ui
The Nomad UI can be accessed at http://$(module.nomadconsul.primary_server_public_ips[0]):4646/ui

CONFIGURATION
}

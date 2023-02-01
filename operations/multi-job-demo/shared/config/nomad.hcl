# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

data_dir = "/opt/nomad/data"
bind_addr = "IP_ADDRESS"

# Enable the server
server {
  enabled = true
  bootstrap_expect = SERVER_COUNT
}

name = "nomad@IP_ADDRESS"

consul {
  address = "IP_ADDRESS:8500"
}

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics       = true
}

acl {
  enabled = true
}

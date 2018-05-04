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

vault {
  enabled = true
  address = "VAULT_URL"
  task_token_ttl = "1h"
  create_from_role = "nomad-cluster"
  token = "TOKEN_FOR_NOMAD"
}

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics       = true
}

# Increase log verbosity
log_level = "INFO"

# Setup data dir
data_dir = "/tmp/client1"

# Enable the client
client {
    enabled = true

    # For demo assume we are talking to server1. For production,
    # this should be like "nomad.service.consul:4647" and a system
    # like Consul used for service discovery.
    servers = ["10.0.3.94:4647"]

  options = {
    "driver.raw_exec.enable" = "1"
  }
}
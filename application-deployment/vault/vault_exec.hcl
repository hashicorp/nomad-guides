# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# John Boero - jboero@hashicorp.com
# A job spec to install and run Vault with 'exec' driver - no Docker.
# Consul not used by default.  Add Consul to config template
# Artifact checksum is for linux-amd64 by default.
job "vault.service" {
  datacenters = ["dc1"]
  type = "service"
  group "vault" {
    count = 1

    task "vault.service" {
      driver = "exec"
      resources {
        cpu = 2000
        memory = 1024
      }

      artifact {
        source      = "https://releases.hashicorp.com/vault/1.7.0/vault_1.7.0_${attr.kernel.name}_${attr.cpu.arch}.zip"
        destination = "/tmp/"
        #options {
        #  checksum = "sha256:2a6958e6c8d6566d8d529fe5ef9378534903305d0f00744d526232d1c860e1ed"
        #}
      }

      template {
        data        = <<EOF
        ui = true
        disable_mlock = true

        # Disable this if you switch to Consul.
        storage "file" {
          path = "/opt/vault/data"
        }

        # Switch to this for Consul
        #storage "consul" {
        #  address = "127.0.0.1:8500"
        #  path    = "vault"
        #}

        # Listen on all IPv4 and IPv6 interfaces.
        listener "tcp" {
          address = ":8200"
          tls_disable = 1
        }
        EOF
        destination = "/etc/vault.d/vault.hcl"
      }
      config {
        command = "/tmp/vault"
        args = ["server", "-config=/etc/vault.d/vault.hcl"]
      }
    }
  }
}

# John Boero - jboero@hashicorp.com
# A job spec to install and run Boundary Worker with 'exec' driver - no Docker.
# Artifact checksum should be added for production.
job "boundary.service" {
  datacenters = ["dc1"]
  type = "service"
  group "controller" {
    # Manage node count here:
    count = 1

    task "worker.task" {
      driver = "exec"
      resources {
        cpu = 2000
        memory = 2048
      }

      artifact {
        source      = "https://releases.hashicorp.com/boundary/0.7.4/boundary_0.7.4_${attr.kernel.name}_${attr.cpu.arch}.zip"
        destination = "/tmp/"
        #options {
        #  checksum = "sha256:[add checksum]"
        #}
      }

      template {
        data        = <<EOF
        listener "tcp" {
            purpose = "proxy"
            tls_disable = true
            address = "0.0.0.0"
        }

        worker {
          # Name attr must be unique across workers
          name = "${attr.unique.hostname}"
          description = "A default worker created demonstration"

          # Workers must be able to reach controllers on :9201
          # If using Consul, suggest NOMAD_UPSTREAM_ADDR_controllers
          controllers = [
            "NOMAD_ADDR_controller"
          ]

          public_addr = "${attr.unique.hostname}"

          tags {
            type   = ["boundary", "workers"]
          }
        }

        # must be same key as used on controller config
        /* /
        kms "aead" {
            purpose = "worker-auth"
            aead_type = "aes-gcm"
            key = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
            key_id = "global_worker-auth"
        }
        /*/
        EOF
        destination = "/etc/boundary/worker.hcl"
      }
      config {
        command = "/tmp/boundary"
        args = ["worker", "-config=/etc/boundary/worker.hcl"]
      }
    }
  }
}

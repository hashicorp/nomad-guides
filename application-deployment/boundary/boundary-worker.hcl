# John Boero - jboero@hashicorp.com
# A job spec to install and run Boundary Worker with 'exec' driver - no Docker.
# Artifact checksum should be added for production.
job "boundary.service" {
  datacenters = ["dc1"]
  type = "service"
  group "worker" {
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
        # Sample Source: https://www.boundaryproject.io/docs/configuration/worker
        listener "tcp" {
            # purpose = api/cluster/proxy
            purpose = "proxy"
          
            #tls_cert_file = "/etc/certs/Boundary.crt"
            #tls_key_file  = "/etc/certs/Boundary.key"
            tls_disable = true
          
            # 127.0.0.1 (loopback), 0.0.0.0 (all IPv4), or :: (all IPv4 and IPv6)
            address = "0.0.0.0"
            
            # Uncomment to enable CORS for the Admin UI. Be sure to set the allowed origin(s)
            # to appropriate values.
            #cors_enabled = true
            #cors_allowed_origins = ["https://yourcorp.yourdomain.com", "serve://boundary"]
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

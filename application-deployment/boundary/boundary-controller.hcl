# John Boero - jboero@hashicorp.com
# A job spec to install and run Boundary Controller with 'exec' driver - no Docker.
# Artifact checksum is for linux-amd64 release by default.
job "boundary.service" {
  datacenters = ["dc1"]
  type = "service"
  group "controller" {
    # Manage node count here:
    count = 1

    task "controller.task" {
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
        # Template HCL generated from documenation page
        # Source: https://www.boundaryproject.io/docs/configuration/controller
        # Disable memory lock: https://www.man7.org/linux/man-pages/man2/mlock.2.html
        disable_mlock = true

        # Controller configuration block
        controller {
          # This name attr must be unique across all controller instances if running in HA mode
          name = "demo-controller-1"
          description = "A controller for a demo!"

          # Database URL for postgres. This can be a direct "postgres://"
          # URL, or it can be "file://" to read the contents of a file to
          # supply the url, or "env://" to name an environment variable
          # that contains the URL.
          database {
              url = "postgresql://boundary:boundarydemo@postgres.yourdomain.com:5432/boundary"
          }
        }

        # API listener configuration block
        listener "tcp" {
          # Should be the address of the NIC that the controller server will be reached on
          address = "::"
          # The purpose of this listener block
          purpose = "api"

          tls_disable = false

          # Uncomment to enable CORS for the Admin UI. Be sure to set the allowed origin(s)
          # to appropriate values.
          #cors_enabled = true
          #cors_allowed_origins = ["https://yourcorp.yourdomain.com", "serve://boundary"]
        }

        # Data-plane listener configuration block (used for worker coordination)
        listener "tcp" {
          # Should be the IP of the NIC that the worker will connect on
          address = "10.0.0.1"
          # The purpose of this listener
          purpose = "cluster"
        }

        # If you're using Vault instead of KMS, use this block for your Vault.
        /* /
        kms "transit" {
          purpose            = "root"
          address            = "https://vault:8200"
          token              = "s.Qf1s5YOURTOKENC1jY"
          disable_renewal    = "false"

          // Key configuration
          key_name           = "transit_key_name"
          mount_path         = "transit/"
          namespace          = "ns1/"

          // TLS Configuration
          tls_ca_cert        = "/etc/vault/ca_cert.pem"
          tls_client_cert    = "/etc/vault/client_cert.pem"
          tls_client_key     = "/etc/vault/ca_cert.pem"
          tls_server_name    = "vault"
          tls_skip_verify    = "false"
        }
        /*/
        
        # Root KMS configuration block: this is the root key for Boundary
        # Use a production KMS such as AWS KMS in production installs
        /* /
        kms "aead" {
          purpose = "root"
          aead_type = "aes-gcm"
          key = "sP1fnF5Xz85RrXyELHFeZg9Ad2qt4Z4bgNHVGtD6ung="
          key_id = "global_root"
        }
        /*/

        # Worker authorization KMS
        # Use a production KMS such as AWS KMS for production installs
        # This key is the same key used in the worker configuration
        /* /
        kms "aead" {
          purpose = "worker-auth"
          aead_type = "aes-gcm"
          key = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
          key_id = "global_worker-auth"
        }
        /*/

        # Recovery KMS block: configures the recovery key for Boundary
        # Use a production KMS such as AWS KMS for production installs
        /* /
        kms "aead" {
          purpose = "recovery"
          aead_type = "aes-gcm"
          key = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
          key_id = "global_recovery"
        }
        /*/
        EOF
        destination = "/etc/boundary/controller.hcl"
      }
      config {
        command = "/tmp/boundary"
        args = ["controller", "-config=/etc/boundary/controller.hcl"]
      }
    }
  }
}

job "nginx" {
  datacenters = ["dc1"]
  type = "service"

  group "nginx" {
    count = 1

    vault {
      policies = ["superuser"]
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx"
        port_map {
          http = 80
        }
        port_map {
          https = 443
        }
        volumes = [
          "custom/default.conf:/etc/nginx/conf.d/default.conf",
          "secret/cert.key:/etc/nginx/ssl/nginx.key",
        ]
      }

      template {
        data = <<EOH
          server {

            listen 443 ssl;

            server_name nginx.service.consul;
            # note this is slightly wonky using the same file for
            # both the cert and key
            ssl_certificate /etc/nginx/ssl/nginx.key;
            ssl_certificate_key /etc/nginx/ssl/nginx.key;

            location / {
              root /local/data/;
            }
          }
        EOH

        destination = "custom/default.conf"
      }

      template {
        data = <<EOH
{{ with secret "pki/issue/consul-service" "common_name=nginx.service.consul" "ttl=30m" }}
{{ .Data.certificate }}
{{ .Data.private_key }}
{{ end }}
EOH

        destination = "secret/cert.key"
      }

      template {
        data = <<EOH
            Good morning.
        EOH

        destination = "local/data/index.html"
      }

      resources {
        cpu    = 100 # 100 MHz
        memory = 128 # 128 MB
        network {
          mbits = 10
          port "http" {
            static = 80
          }
          port "https" {
            static = 443
          }
        }
      }

      service {
        name = "nginx"
        tags = ["frontend","urlprefix-/nginx strip=/nginx"]
        port = "http"
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}

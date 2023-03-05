job "caddy" {
  datacenters = ["dc1"]
  type        = "service"
  group "caddy" {
    count = 1
    network {
      port "http" {
        static = 80
      }
      port "https" {
        static = 443
      }

    }
    task "caddy" {
      driver = "docker"
      config {
        image = "caddy:alpine"
        ports = ["http", "https"]
        volumes = [
          "custom/Caddyfile:/etc/caddy/Caddyfile"
        ]
      }
      template {
        data        = <<EOH
localhost, caddy.service.consul {
  tls internal
  root * /local/data/caddy
  file_server
}
EOH
        destination = "custom/Caddyfile"
      }
      # consul kv put features/demo 'Consul Rocks!'
      template {
        data        = <<EOH
        Nomad Template example (Consul value)
        <br />
        <br />
        {{ if keyExists "features/demo" }}
        Consul Key Value:  {{ key "features/demo" }}
        {{ else }}
          Good morning.
        {{ end }}
        <br />
        <br />
        Node Environment Information:  <br />
        node_id:     {{ env "node.unique.id" }} <br/>
        datacenter:  {{ env "NOMAD_DC" }}
        Test
        EOH
        destination = "local/data/caddy/index.html"
      }
      resources {
        cpu    = 100 # 100 MHz
        memory = 128 # 128 MB
      }
      service {
        name = "caddy"
        tags = ["caddy", "web", "urlprefix-/"]
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

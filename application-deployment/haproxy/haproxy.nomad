job "lb" {
  region = "global"
  datacenters = ["dc1"]
  type = "service"
  update {
    stagger = "10s"
    max_parallel = 1
  }
  group "lb" {
    count = 3
    restart {
      interval = "5m"
      attempts = 10
      delay = "25s"
      mode = "delay"
    }
    task "haproxy" {
      driver = "docker"
      config {
        image = "haproxy"
        network_mode = "host"
        port_map {
          http = 80
        }
        volumes = [
          "custom/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg"
        ]
      }
      template {
        #source = "haproxy.cfg.tpl"
        data = <<EOH
        global
          debug
        defaults
          log global
          mode http
          option httplog
          option dontlognull
          timeout connect 5000
          timeout client 50000
          timeout server 50000
        frontend http_front
          bind *:80
          stats uri /haproxy?stats
          default_backend http_back 
        listen nomad
          bind 0.0.0.0:3646
          balance roundrobin {{range service "nomad" }}
          server {{.Node}} {{.Address}}:4646 check{{end}}
        listen vault
          bind 0.0.0.0:3200
          balance roundrobin 
          option httpchk GET /v1/sys/health{{range service "vault"}}
          server {{.Node}} {{.Address}}:8200 check{{end}}
        listen consul
          bind 0.0.0.0:3500
          balance roundrobin {{range service "consul" }}
          server {{.Node}} {{.Address}}:8500 check{{end}}
        backend http_back
 					balance roundrobin{{range service "go-app"}}
					server {{.Node}} {{.Address}}:{{.Port}} check{{end}}
        EOH

        destination = "custom/haproxy.cfg"
      }
      service {
        name = "haproxy"
        tags = [ "global", "lb", "urlprefix-/haproxy" ]
        port = "http"
        check {
          name = "alive"
          type = "tcp"
          interval = "10s"
          timeout = "2s"
        }
      }
      resources {
        cpu = 500 # 500 Mhz
        memory = 128 # 128MB
        network {
          mbits = 10
          port "http" {
            static = 80
          }
        }
      }
    }
  }
}


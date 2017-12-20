
job "fabio" {
  datacenters = ["dc1"]
  type = "system"

  group "fabio" {
    count = 1

    task "fabio" {
      driver = "raw_exec"

      artifact {
        source = "https://github.com/fabiolb/fabio/releases/download/v1.5.4/fabio-1.5.4-go1.9.2-linux_amd64"
      }

      config {
        command = "fabio-1.5.4-go1.9.2-linux_amd64"
      }

      resources {
        cpu    = 100 # 500 MHz
        memory = 128 # 256MB
        network {
          mbits = 10
          port "http" {
            static = 9999
          }
          port "admin" {
            static = 9998
          }
        }
      }
    }
  }
}
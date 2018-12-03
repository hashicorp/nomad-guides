job "website" {
  datacenters = ["dc1"]
  namespace = "dev"

  constraint {
    attribute = "${attr.kernel.name}"
    value = "linux"
  }

  update {
    stagger = "10s"
    max_parallel = 1
  }

  group "nginx" {
    count = 2

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    # - db - #
    task "nginx" {
      driver = "docker"

      config {
        image = "nginx:1.15.6"
        port_map = {
          http = 80
        }
      }

      service {
        name = "nginx-dev"
        tags = ["web", "nginx", "dev"]
        port = "http"
      }

      resources {
        cpu = 500 # 500 Mhz
        memory = 512 # 512MB
        network {
          mbits = 10
          port "http" {}
        }
      }
    } # - end task - #
  } # - end group - #

  group "mongodb" {
    count = 2

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    # - db - #
    task "mongodb" {
      driver = "docker"

      config {
        image = "mongo:3.4.3"
        port_map = {
          http = 27017
        }
      }

      service {
        name = "mongodb-dev"
        tags = ["db", "mongodb", "dev"]
        port = "http"
      }

      resources {
        cpu = 500 # 500 Mhz
        memory = 512 # 512MB
        network {
          mbits = 10
          port "http" {}
        }
      }
    } # - end task - #
  } # - end group - #

}

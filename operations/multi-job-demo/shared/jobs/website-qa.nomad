job "website" {
  datacenters = ["dc1"]
  namespace = "qa"

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
        name = "nginx-qa"
        tags = ["web", "nginx", "qa"]
        port = "http"
      }

      resources {
        cpu = 500 # 500 Mhz
        memory = 1024 # 1024MB
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
        name = "mongodb-qa"
        tags = ["db", "mongodb", "qa"]
        port = "http"
      }

      resources {
        cpu = 500 # 500 Mhz
        memory = 1024 # 1024MB
        network {
          mbits = 10
          port "http" {}
        }
      }
    } # - end task - #
  } # - end group - #

}

# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

job "webserver-test" {
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

  group "webserver" {
    count = 2

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    # - db - #
    task "webserver" {
      driver = "docker"

      config {
        # "httpd" is not an allowed image
        image = "httpd"
        port_map = {
          http = 80
        }
      }

      service {
        name = "webserver-test"
        tags = ["test", "webserver", "qa"]
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

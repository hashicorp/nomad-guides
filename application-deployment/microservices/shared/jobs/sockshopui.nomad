# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

job "sockshopui" {
  datacenters = ["dc1"]

  type = "system"

  constraint {
    attribute = "${attr.kernel.name}"
    value = "linux"
  }

  update {
    stagger = "10s"
    max_parallel = 1
  }

  # - frontend #
  group "frontend" {

  restart {
    attempts = 10
    interval = "5m"
    delay = "25s"
    mode = "delay"
  }

    # - frontend app - #
    task "front-end" {
      driver = "docker"

      config {
        image = "weaveworksdemos/front-end:master-ac9ca707"
        command = "/usr/local/bin/node"
        args = ["server.js", "--domain=service.consul"]
        hostname = "front-end.service.consul"
        network_mode = "sockshop"
        port_map = {
          http = 8079
        }
      }

      service {
        name = "front-end"
        tags = ["app", "frontend", "front-end"]
        port = "http"
      }

      resources {
        cpu = 100 # 100 Mhz
        memory = 128 # 128MB
        network {
          mbits = 10
          port "http" {
            static = 80
          }
        }
      }
    } # - end frontend app - #
  } # - end frontend - #
}

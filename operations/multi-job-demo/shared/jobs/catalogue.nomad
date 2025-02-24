# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

job "catalogue" {
  datacenters = ["dc1"]

  constraint {
    attribute = "${attr.kernel.name}"
    value = "linux"
  }

  update {
    stagger = "10s"
    max_parallel = 1
  }


  # - catalogue - #
  group "catalogue" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    # - app - #
    task "catalogue" {
      driver = "docker"

      config {
        image = "rberlind/catalogue:latest"
        command = "/app"
        args = ["-port", "8080", "-DSN", "catalogue_user:default_password@tcp(127.0.0.1:3306)/socksdb"]
        hostname = "catalogue.service.consul"
        network_mode = "host"
        port_map = {
          http = 8080
        }
      }

      service {
        name = "catalogue"
        tags = ["app", "catalogue"]
        port = "http"
      }

      resources {
        cpu = 100 # 100 Mhz
        memory = 128 # 32MB
        network {
          mbits = 10
          port "http" {
            static = 8080
          }
        }
      }
    } # - end app - #

    # - db - #
    task "cataloguedb" {
      driver = "docker"

      config {
        image = "rberlind/catalogue-db:latest"
        hostname = "catalogue-db.service.consul"
        command = "docker-entrypoint.sh"
        args = ["mysqld", "--bind-address", "127.0.0.1"]
        network_mode = "host"
        port_map = {
          http = 3306
        }
      }

      env {
        MYSQL_DATABASE = "socksdb"
        MYSQL_ALLOW_EMPTY_PASSWORD = "true"
      }

      service {
        name = "catalogue-db"
        tags = ["db", "catalogue", "catalogue-db"]
        port = "http"
      }

      resources {
        cpu = 100 # 100 Mhz
        memory = 256 # 256MB
        network {
          mbits = 10
          port "http" {
            static = 3306
          }
        }
      }

    } # - end db - #

  } # - end group - #
}

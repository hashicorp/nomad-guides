# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

job "app" {
  datacenters = ["dc1"]
  type = "service"

  update {
    stagger = "5s"
    max_parallel = 1
  }

  group "app" {
    count = 3

    task "app" {
      driver = "exec"
      config {
        command = "goapp"
      }

      env {
        VAULT_ADDR = "http://active.vault.service.consul:8200"
        APP_DB_HOST = "db.service.consul:3306"
      }

      vault {
        policies = [ "mysql" ]
      }

      artifact {
        source = "https://s3.amazonaws.com/ak-bucket-1/goapp"
      }

      resources {
        cpu = 500
        memory = 64
        network {
          mbits = 1
          port "http" {
	          static = 8080
	        }
        }
      }

      service {
        name = "app"
        tags = ["urlprefix-/app", "go-mysql-app"]
        port = "http"
        check {
          type = "http"
          name = "healthz"
          interval = "15s"
          timeout = "5s"
          path = "/healthz"
        }
      }
    }
  }
}

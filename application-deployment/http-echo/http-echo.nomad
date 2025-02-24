# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

job "docs" {
  datacenters = ["dc1"]

  group "example" {
    task "server" {
      driver = "exec"

      config {
        command = "/bin/http-echo"
        args = [
          "-listen", ":5678",
          "-text", "hello world",
        ]
      }

      resources {
        network {
          mbits = 10
          port "http" {
            static = "5678"
          }
        }
      }
    }
  }
}

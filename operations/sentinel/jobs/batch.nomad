# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

job "uptime" {
  datacenters = ["dc1"]

  type = "batch"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "example" {
    count = 1
    task "uptime" {
      driver = "exec"
      config {
        command = "uptime"
      }
    }
  }
}

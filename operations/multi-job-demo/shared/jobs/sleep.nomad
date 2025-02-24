# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

job "sleep" {
  datacenters = ["dc1"]

  task "sleep" {
    driver = "exec"

    config {
      command = "/bin/sleep"
      args    = ["60"]
    }
  }
}

# Copyright IBM Corp. 2017, 2026

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

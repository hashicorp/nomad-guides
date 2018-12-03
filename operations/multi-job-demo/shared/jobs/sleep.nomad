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

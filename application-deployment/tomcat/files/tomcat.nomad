job "tomcat" {
  datacenters = ["dc1"]

  group "production" {
    task "server" {
      driver = "raw_exec"

      config {
        command = "/usr/local/bin/starttomcat.sh"
      }

      resources {
        network {
          mbits = 10
          port "http" {
            static = "8080"
          }
        }
      }
    }
  }
}
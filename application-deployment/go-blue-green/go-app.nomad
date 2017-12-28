job "go-app" {
  datacenters = ["dc1"]
  type = "service"
  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    auto_revert = false
    canary = 3
  }
  group "go-app" {
    count = 3
    restart {
      # The number of attempts to run the job within the specified interval.
      attempts = 10
      interval = "5m"
      # The "delay" parameter specifies the duration to wait before restarting
      # a task after it has failed.
      delay = "25s"
      mode = "delay"
    }
    ephemeral_disk {
      size = 300
    }
    task "go-app" {
      # The "driver" parameter specifies the task driver that should be used to
      # run the task.
      driver = "docker"
      config {
        # change to go-app-2.0 
        image = "aklaas2/go-app-2.0"
        port_map {
          http = 8080
        }
      }
      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB
        network {
          mbits = 10
          port "http" {
	           #static=8080
	        }
        }
      }
      service {
        name = "go-app"
        tags = [ "urlprefix-/go-app", "go-app" ]
        port = "http"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}

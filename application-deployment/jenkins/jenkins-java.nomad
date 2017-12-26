job "jenkins" {
  type = "service"
    datacenters = ["dc1"]
    update {
      stagger      = "30s"
        max_parallel = 1
    }
#  constraint {
#    attribute = "${driver.java.version}"
#    operator  = ">"
#    value     = "1.7.0"
#  }
  group "web" {
    count = 1
      # Size of the ephemeral storage for Jenkins. Consider that depending
      # on job count and size it could require larger storage.
      ephemeral_disk {
       migrate = true
       size    = "500"
       sticky  = true
       
     }
    task "frontend" {
      env {
        # Use ephemeral storage for Jenkins data.
        JENKINS_HOME = "/alloc/data"
        JENKINS_SLAVE_AGENT_PORT = 5050
      }
      driver = "java"
      config {
        jar_path    = "local/jenkins.war"
        jvm_options = ["-Xmx768m", "-Xms384m"]
        args        = ["--httpPort=8080"]
      }
      artifact {
        source = "http://ftp-chi.osuosl.org/pub/jenkins/war-stable/2.46.2/jenkins.war"

        options {
          # Checksum will change depending on the Jenkins Version.
          checksum = "sha256:aa7f243a4c84d3d6cfb99a218950b8f7b926af7aa2570b0e1707279d464472c7"
        }
      }
      service {
        # This tells Consul to monitor the service on the port
        # labeled "http".
        port = "http"
        name = "jenkins"

        check {
          type     = "http"
          path     = "/login"
          interval = "10s"
          timeout  = "2s"
        }
    }

      resources {
          cpu    = 2400 # MHz
          memory = 768 # MB
          network {
            mbits = 100
            port "http" {
                static = 8080
            }
            port "slave" {
              static = 5050
            }
          }
        }
      }
    }
}

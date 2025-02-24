# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

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
        source = "http://mirrors.jenkins.io/war-stable/2.150.3/jenkins.war"

        options {
          # Checksum will change depending on the Jenkins Version.
          checksum = "sha256:4fc2700a27a6ccc53da9d45cc8b2abd41951b361e562e1a1ead851bea61630fd"
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

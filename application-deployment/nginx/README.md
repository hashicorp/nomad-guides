# Nginx Deployment (Template Example)
The goal of this guide is to help users deploy Nginx on Nomad. In the process we will also show how to use Nomad templating to update the configuration of our deployed tasks. (Nomad uses Consul Template under the hood) 

### TLDR;
```bash
vagrant@node1:/vagrant/application-deployment/nginx$ ./kv_consul_setup.sh

vagrant@node1:/vagrant/application-deployment/nginx$ nomad run nginx-consul.nomad

#Validate the results on Nomad clients, job assigns static port 8080 
#if using vagrantfile check:
http://localhost:8080/nginx/

```

## Estimated Time to Complete
10 minutes

## Prerequisites
A Nomad cluster should be up and running. Setup a cluster with OSS or enterprise binaries using the vagrantfile here: https://github.com/hashicorp/nomad-guides/tree/master/provision/vagrant

## Challenge
Keeping environment variables and application configuration files up to date in a dynamic or microservice environment can be difficult to manage and scale.

## Solution
Nomad's template block instantiates an instance of a template renderer. This creates a convenient way to ship configuration files that are populated from environment variables, Consul data, Vault secrets, or just general configurations within a Nomad task.

In this example, we will leverage Consul for our tasks' configuration and deploy Nginx containers.

# Steps

## Step 1: Write a Test Value to Consul 
Write the test value to Consul (script included)

```bash
vagrant@node1:/vagrant/application-deployment/nginx$ cat kv_consul_setup.sh
#!/bin/bash

consul kv put features/demo 'Consul Rocks!'

vagrant@node1:/vagrant/application-deployment/nginx$ ./kv_consul_setup.sh
Success! Data written to: features/demo
```

## Step 2: Review Template stanza
The important piece of this example lies in the template stanza
```
     template {
        data = <<EOH
        Nomad Template example (Consul value)
        <br />
        <br />
        {{ if keyExists "features/demo" }}
        Consul Key Value:  {{ key "features/demo" }}
        {{ else }}
          Good morning.
        {{ end }}
        <br />
        <br />
        Node Environment Information:  <br />
        node_id:     {{ env "node.unique.id" }} <br/>
        datacenter:  {{ env "NOMAD_DC" }}
        EOH
        destination = "local/data/nginx/index.html"
      }
```

In this example the `if KeyExists` block instructs Nomad to pull a value from the Consul key `features/demo` if it exists. We wrote this Consul value in step 1.

We can also use Nomad's interpolation features to populate config/env variables based on Nomad's runtime information. The `env "node.unique.id"` and `env "NOMAD_DC"` options showcase this. More information is provided here: https://www.nomadproject.io/docs/runtime/interpolation.html

Nomad will populate the template with those values and place the rendered template file in the specified `destination` location. 

More template options are outlined here: https://www.nomadproject.io/docs/job-specification/template.html

## Step 3: Run the Job
Run the nginx job
```bash
vagrant@node1:/vagrant/application-deployment/nginx$ nomad run nginx-consul.nomad
==> Monitoring evaluation "61609418"
    Evaluation triggered by job "nginx"
    Allocation "850b5877" created: node "7de3fca4", group "nginx"
    Allocation "40b89ff1" created: node "c4146f97", group "nginx"
    Allocation "52d61bf4" created: node "def34073", group "nginx"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "61609418" finished with status "complete"

vagrant@node1:/vagrant/application-deployment/nginx$ nomad status nginx
ID            = nginx
Name          = nginx
Submit Date   = 12/27/17 20:54:21 UTC
Type          = service
Priority      = 50
Datacenters   = dc1
Status        = running
Periodic      = false
Parameterized = false

Summary
Task Group  Queued  Starting  Running  Failed  Complete  Lost
nginx       0       0         3        0       0         0

Allocations
ID        Node ID   Task Group  Version  Desired  Status   Created At
40b89ff1  c4146f97  nginx       0        run      running  12/27/17 20:54:21 UTC
52d61bf4  def34073  nginx       0        run      running  12/27/17 20:54:21 UTC
850b5877  7de3fca4  nginx       0        run      running  12/27/17 20:54:21 UTC
```

## Step 4: Validate results
Use Curl or your Browser to validate the tempalte was rendered correctly.

```bash
vagrant@node1:/vagrant/application-deployment/nginx$ curl http://10.0.2.15:8080/nginx/
        Nomad Template example (Consul value)
        <br />
        <br />

        Consul Key Value:  Consul Rocks!

        <br />
        <br />
        Node Environment Information:  <br />
        node_id:     def34073-b34d-240d-9155-1adaa8e5da74 <br/>
        datacenter:  dc1
```
Browser (using Vagrantfile):
![](https://raw.githubusercontent.com/hashicorp/nomad-guides/master/assets/Nginx_Consul.png)



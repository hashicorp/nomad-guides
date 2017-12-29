# Fabio Load Balancer Deployment 
In this example we will deploy fabio load balancers across our worker nodes. Fabio is a loadbalancer that natively integrates with Consul to dynamically create routes for our other deployed Nomad services.

### TLDR;
```bash
vagrant@node1:/vagrant/application-deployment/fabio$ nomad run fabio.nomad

#Check the fabio GUI (Adjust IP for your setup, this example assumes the Vagrantfile)
http://localhost:9998/routes

#After we register services with Consul using "urlprefix-/app" we will be able to reach them via port 9999
```

## Estimated Time to Complete
5 minutes

## Prerequisites
A Nomad cluster should be up and running. Setup a cluster with OSS or enterprise binaries using the vagrantfile here: https://github.com/hashicorp/nomad-guides/tree/master/provision/vagrant

## Challenge

Keeping load balancers and webservers up to date in a microservice environment is difficult due to their ephemeral nature. Many legacy load balancers require a static config file to be reloaded whenever service IP's/routes change. 


## Solution

Fabio is a fast, modern, zero-conf load balancing HTTP(S) and TCP router for deploying applications managed by consul.

Using Nomad, we can deploy fabio across our worker nodes. Whenever we launch new jobs on Nomad, we can specify a special Consul tag that Fabio will detect. Once detected, Fabio will then dynamically create routes to those services.

# Steps

## Step 1: Review Fabio job file.
https://github.com/hashicorp/nomad-guides/blob/master/application-deployment/fabio/fabio.nomad

## Step 2: Using Fabio
This will be covered more in the goapp guide covered here: https://github.com/hashicorp/nomad-guides/tree/master/application-deployment/go-blue-green

Here is a quick overview:

When registering our service stanza in a Nomad job file, we can define Consul tags. Fabio looks for a specific tag. If found, Fabio will create a route to that task's address and port automatically. This removes any need for templating or updating hardcoded configuration files.

An example Nomad job config:
```bash
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
```
The `urlprefix-` instructs fabio to create a dynamic route to this task. More details are described here: (https://github.com/fabiolb/fabio#getting-started). 
Examples:
```bash
# HTTP/S examples
urlprefix-/css                                     # path route
urlprefix-i.com/static                             # host specific path route
urlprefix-mysite.com/                              # host specific catch all route
urlprefix-/foo/bar strip=/foo                      # path stripping (forward '/bar' to upstream)
urlprefix-/foo/bar proto=https                     # HTTPS upstream
urlprefix-/foo/bar proto=https tlsskipverify=true  # HTTPS upstream and self-signed cert

# TCP examples
urlprefix-:3306 proto=tcp                          # route external port 3306
```

We will be able to leverage this in another example by visiting the `http://FABIO_IP:9999/go-app/`

## Step 3: Launch the Fabio job file

```bash
vagrant@node1:/vagrant/application-deployment/fabio$ nomad run fabio.nomad
==> Monitoring evaluation "38d1f1b5"
    Evaluation triggered by job "fabio"
    Allocation "6c9a970e" created: node "c4146f97", group "fabio"
    Allocation "8819ad04" created: node "7de3fca4", group "fabio"
    Allocation "8c6a23c5" created: node "def34073", group "fabio"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "38d1f1b5" finished with status "complete"
```
Check the status
```bash
vagrant@node1:/vagrant/application-deployment/fabio$ nomad status fabio
ID            = fabio
Name          = fabio
Submit Date   = 12/27/17 21:36:31 UTC
Type          = system
Priority      = 50
Datacenters   = dc1
Status        = running
Periodic      = false
Parameterized = false

Summary
Task Group  Queued  Starting  Running  Failed  Complete  Lost
fabio       0       0         3        0       0         0

Allocations
ID        Node ID   Task Group  Version  Desired  Status   Created At
6c9a970e  c4146f97  fabio       0        run      running  12/27/17 21:36:31 UTC
8819ad04  7de3fca4  fabio       0        run      running  12/27/17 21:36:31 UTC
8c6a23c5  def34073  fabio       0        run      running  12/27/17 21:36:31 UTC
```

## Step 4: Check the Fabio GUI
Visit the IP address of a Nomad worker node.

If using the Vagrantfile visit http://localhost:9998/routes

The Fabio GUI should load. However, there will not be any populated routes yet. See the next steps section below. We will cover another guide that will utilize Fabio.

![](https://raw.githubusercontent.com/hashicorp/nomad-guides/master/assets/Fabio_GUI_empty.png)

# Next Steps:
See an example of Fabio dynamic route creation in this goapp (Golang) example: 
https://github.com/hashicorp/nomad-guides/tree/master/application-deployment/go-blue-green

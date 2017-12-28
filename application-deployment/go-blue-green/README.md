# Golang app example Part 1:(Dynamic routing), Part 2:(blue-green upgrade)
This guide will cover two examples. Part 1 will cover a dynamic routing example using Fabio and a Golang docker app. Part 2 will cover a blue-green upgrade of that app.

### Demo TLDR:
```bash
##PART 1
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad run /vagrant/application-deployment/fabio/fabio.nomad

#containers takes a minute or two to download and start
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad run go-app.nomad

#in your browser go to 
http://localhost:9998/routes

#in your browser go to "golang 1.9 out yet?"
http://localhost:9999/go-app/

##PART 2
#Make the following change to the go-app.nomad image
image = "aklaas2/go-app-1.0"
#to
image = "aklaas2/go-app-2.0"

#See canaries
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad plan go-app.nomad

vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad run go-app.nomad

#There should be 6 allocs now (three old image)(three new image)
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad status go-app

#Grab job ID from status
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad deployment promote 562b9ba3

#Back to only 3 allocs with the new image
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad status go-app

#in your browser see upgraded app "golang 2.0 out yet?"
http://localhost:9999/go-app/

```

## Estimated Time to Complete
20 minutes

## Prerequisites
A Nomad cluster should be up and running. Setup a cluster with OSS or enterprise binaries using the vagrantfile here: https://github.com/hashicorp/nomad-guides/tree/master/provision/vagrant

Part 1 (load balancing) requires fabio to be up and running. Follow the guide here: https://github.com/hashicorp/nomad-guides/tree/master/application-deployment/fabio

Part 1 is optional and not required for part 2.

# Part 1 (Fabio Dynamic Routing)

## Challenge
Orchestrators and microservice architectures enable operatores and developers to more efficiently utilize their compute resources and manage the lifecycles of their applicaitons. However, the highly ephemeral nature of these technologies makes configuration, load balancing, and service discovery difficult.

## Solution
We can leverage Nomad, Consul, and load balancers like Fabio to automtically create routes to our containers. This removes the need for hardcoded configurations and enables our microservices to locate one another.

## Step 1: Review go-app.nomad
The golang code for this docker image is from the simple golang "outyet" example posted here: https://github.com/golang/example/tree/master/outyet.

Nomad job file go-app.nomad:
```bash
    task "go-app" {
      # The "driver" parameter specifies the task driver that should be used to
      # run the task.
      driver = "docker"
      config {
        # change to go-app-2.0
        image = "aklaas2/go-app-1.0"
        port_map {
          http = 8080
        }
      }
```

Lets take a look at the service stanza of our job file. The `urlprefix-/goapp` tag is registered in Consul for this service. Fabio looks for this tag and will create a dynamic route to the IP address and port given to this container. It will create a route to the path `/go-app`
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
## Step 2: Deploy the go-app
Make sure Fabio is running
```bash
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad status fabio
. . .
Allocations
ID        Node ID   Task Group  Version  Desired  Status   Created At
859225e5  c4b9b97e  fabio       0        run      running  12/28/17 15:49:59 UTC
b75530ea  34bec70a  fabio       0        run      running  12/28/17 15:49:59 UTC
c8a8bf79  a79b11ff  fabio       0        run      running  12/28/17 15:49:59 UTC
```
Now run the go-app
```bash
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad run go-app.nomad
==> Monitoring evaluation "a4c273c1"
    Evaluation triggered by job "go-app"
    Evaluation within deployment: "1ecf8fd1"
    Allocation "48bd05a4" created: node "a79b11ff", group "go-app"
    Allocation "b25f41fd" created: node "c4b9b97e", group "go-app"
    Allocation "c59f836c" created: node "34bec70a", group "go-app"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "a4c273c1" finished with status "complete"
```
It may take a few minutes for the image to download and start running.
```bash
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad status go-app
. . .
Allocations
ID        Node ID   Task Group  Version  Desired  Status   Created At
48bd05a4  a79b11ff  go-app      0        run      running  12/28/17 16:05:19 UTC
b25f41fd  c4b9b97e  go-app      0        run      running  12/28/17 16:05:19 UTC
c59f836c  34bec70a  go-app      0        run      running  12/28/17 16:05:19 UTC
```

## Step 3: Validate Routes
Once finished check the Fabio GUI to verify routes were created.
If using the Vagrantfile go to http://localhost:9998/routes
![](https://raw.githubusercontent.com/hashicorp/nomad-guides/master/assets/Fabio_GUI_goapp.png)

Note the dynamic port numbers assigned by Nomad.

Now lets check the app using Fabio's 9999 port and the path route for our go-app: http://localhost:9999/go-app/
![](https://raw.githubusercontent.com/hashicorp/nomad-guides/master/assets/go-app-v1.png)



# Part 2 (Blue-Green Upgrade)

## Challenge
Most applications are long-lived and require updates over time. This can be very difficult in legacy environments were manual procceses and a variety of scripts need to be done in proper order. Using a scheduler helps this situation by integrating features such as health checks, rollbacks, and canaries.

## Solution
 Nomad has built-in support for rolling, blue/green, and canary updates. When a job specifies a rolling update, Nomad uses task state and health check information in order to detect allocation health and minimize or eliminate downtime.

## Step 1: Review the Update Stanza
Upgrade strategies are enabled by configuring the update stanza. Detailed notes are described here: https://www.nomadproject.io/docs/operating-a-job/update-strategies/index.html.
This example will cover a blue-green upgrade. 

```bash
  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    auto_revert = false
    canary = 3
  }
  group "go-app" {
    count = 3
```
The important bits:
In our example we are launching 3 instances of the go-app. To perform a blue-green we want an equal size green deployment. So we set `canary = 3`. This instructs Nomad to create 3 new allocations with the upgraded app alongside our existing allocations.

See: https://www.nomadproject.io/docs/job-specification/update.html for explanations on the other config options.



## Step 2: Run V1 of the go-app
Make sure the go-app image is using version 1.
```bash
      config {
        # change to go-app-2.0 
        image = "aklaas2/go-app-1.0"
        port_map {
          http = 8080
        }
      }
```
Run the go-app
```bash
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad run go-app.nomad
==> Monitoring evaluation "a4c273c1"
    Evaluation triggered by job "go-app"
    Evaluation within deployment: "1ecf8fd1"
    Allocation "48bd05a4" created: node "a79b11ff", group "go-app"
    Allocation "b25f41fd" created: node "c4b9b97e", group "go-app"
    Allocation "c59f836c" created: node "34bec70a", group "go-app"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "a4c273c1" finished with status "complete"
```
It may take a few minutes for the image to download and start running.

If using Fabio, verify the app is running. You can also assign a static port and check using that. If you want to assign a static port uncomment `#static=8080`, Nomad will assign 8080 to the container on your clients (Make sure you don't have collisions by assigning more than one contianer per host).

```bash
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
```

![](https://raw.githubusercontent.com/hashicorp/nomad-guides/master/assets/go-app-v1.png)

## Step 3: Update the go-app job file
Make the following change to the go-app.nomad image
`image = "aklaas2/go-app-1.0"`
to
`image = "aklaas2/go-app-2.0"`

Next perform a plan on the go-app job file.

## Step 4: Nomad plan
Perform a dry-run
```bash
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad plan go-app.nomad
+/- Job: "go-app"
+/- Task Group: "go-app" (3 canary, 3 ignore)
  +/- Task: "go-app" (forces create/destroy update)
    +/- Config {
      +/- image:             "aklaas2/go-app-1.0" => "aklaas2/go-app-2.0"
          port_map[0][http]: "8080"
        }

Scheduler dry-run:
- All tasks successfully allocated.
```
Notice the Task Group: Nomad will place 3 canaries with the updated image.

## Step 5: Nomad run
Run the job
```bash
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad run go-app.nomad
==> Monitoring evaluation "e878b283"
    Evaluation triggered by job "go-app"
    Evaluation within deployment: "95eceb6a"
    Allocation "2f776f18" created: node "34bec70a", group "go-app"
    Allocation "3ba671a1" created: node "a79b11ff", group "go-app"
    Allocation "82f71f8d" created: node "c4b9b97e", group "go-app"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "e878b283" finished with status "complete"
```
Check the status, notice there are now 6 allocations (3 with new version of job file).
```bash
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad status go-app
. . .
. . .
Allocations
ID        Node ID   Task Group  Version  Desired  Status   Created At
2f776f18  34bec70a  go-app      1        run      running  12/28/17 16:49:03 UTC
3ba671a1  a79b11ff  go-app      1        run      running  12/28/17 16:49:03 UTC
82f71f8d  c4b9b97e  go-app      1        run      running  12/28/17 16:49:03 UTC
48bd05a4  a79b11ff  go-app      0        run      running  12/28/17 16:05:19 UTC
b25f41fd  c4b9b97e  go-app      0        run      running  12/28/17 16:05:19 UTC
c59f836c  34bec70a  go-app      0        run      running  12/28/17 16:05:19 UTC
```

## Step 6: Finish deployment

Once testing of the new application is complete, we can promote the deployment

```bash
vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad deployment promote 95eceb6a
==> Monitoring evaluation "f27de937"
    Evaluation triggered by job "go-app"
    Evaluation within deployment: "95eceb6a"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "f27de937" finished with status "complete"

vagrant@node1:/vagrant/application-deployment/go-blue-green$ nomad status go-app
. . .
. . .
Allocations
ID        Node ID   Task Group  Version  Desired  Status    Created At
2f776f18  34bec70a  go-app      1        run      running   12/28/17 16:49:03 UTC
3ba671a1  a79b11ff  go-app      1        run      running   12/28/17 16:49:03 UTC
82f71f8d  c4b9b97e  go-app      1        run      running   12/28/17 16:49:03 UTC
48bd05a4  a79b11ff  go-app      0        stop     complete  12/28/17 16:05:19 UTC
b25f41fd  c4b9b97e  go-app      0        stop     complete  12/28/17 16:05:19 UTC
c59f836c  34bec70a  go-app      0        stop     complete  12/28/17 16:05:19 UTC
```

Once the deployment is promoted, check the app to verify the upgrade (the website should now be checking if golang 2.0 is out yet!).

![](https://raw.githubusercontent.com/hashicorp/nomad-guides/master/assets/go-app-v2.png)
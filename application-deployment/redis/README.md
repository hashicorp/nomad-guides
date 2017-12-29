# Redis Service Deployment (introduction to Nomad job operations)
The goal of this guide is to help users get started with deplying jobs on Nomad. In this Guide we will walk through some simple operational commands in Nomad and deploy some Redis Docker containers.

## Estimated Time to Complete
20 minutes

## Prerequisites
A Nomad cluster should be up and running. Setup a cluster with OSS or enterprise binaries using the vagrantfile here: https://github.com/hashicorp/nomad-guides/tree/master/provision/vagrant

## Challenge
Containerization improved developer workflows but also enabled an immutable application deployment strategy decoupled from the infrastructure lifecycle. This is an attractive alternative to baking new AMIs for every release. However current solutions can be difficult to interact with and scale.

## Solution

Nomad is operationally simlpe to setup, supports several workload types (driver, exec, qemu, lxc, etc.), supports multi-region out of the box, and is easy to use by both oeprators and developers through job files.

Jobs are the primary configuration that users interact with when using Nomad. A job is an easy to write, declarative specification of tasks that Nomad should run. Jobs have a globally unique name, one or many task groups, which are themselves collections of one or many tasks.



# Steps
In this example we will walk through some simple CLI commands for deploying and managing Nomad jobs. First, go through `redis.nomad` in depth and take to time review all the available job configuration options. Note: `redis.nomad` can be created by using the `nomad init` command. More information here: https://www.nomadproject.io/intro/getting-started/jobs.html

## Step 0: Review redis.nomad (example.nomad)
Read about all the Nomad job config options:
https://github.com/hashicorp/nomad-guides/blob/master/application-deployment/redis/redis.nomad
Details are documented in depth here:
https://www.nomadproject.io/docs/job-specification/index.html

Some important bits:
``` bash
    task "redis" {           # The task stanza specifices a task (unit of work) within a group
      . . .
      driver = "docker"      # This task uses Docker, other examples: exec, LXC, QEMU
      config {
        image = "redis:3.2"  # Docker image to download (uses public hub by default)
        port_map {           # Port on container you would like to map to chosen dynamic port on host
          db = 6379
        }
      }
      . . .
      resources {    # Resource limits to reserve for this task
        cpu    = 500 # 500 MHz, capacity is calculated by (CPU Freq * Num CPUs)
        memory = 256 # 256MB
        network {
          mbits = 10
          port "db" {} # Allocate a dynamic port called "db"
        }
      }
      . . .
      service {       # Register this task in Consul and define health checks
        name = "global-redis-check" 
        tags = ["global", "cache"]
        port = "db"  # Health check will be performed against dynamic port named "db" from above
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
```

A job is made up of one or more groups. A group is made up of one or more tasks. All tasks witin a group (taskgroup) will be placed on the same Nomad worker node.

## Step 1: Create Nomad ACL bootstrap token
If you haven't yet, set a Nomad acl token with proper permissions to deploy jobs. We will be using the bootstrap (admin) token here.

```bash
vagrant@node1:~$ nomad acl bootstrap
Accessor ID  = 2233ea44-bfa1-d6d9-1608-4aee6540bab3
Secret ID    = e4d0754e-2608-d936-b668-0f463bec2325
Name         = Bootstrap Token
Type         = management
Global       = true
Policies     = n/a
Create Time  = 2017-12-27 19:35:59.925737871 +0000 UTC
Create Index = 31
Modify Index = 31

vagrant@node1:~$ export NOMAD_TOKEN=e4d0754e-2608-d936-b668-0f463bec2325

vagrant@node1:~$ nomad server-members
Name          Address         Port  Status  Leader  Protocol  Build      Datacenter  Region
node1.global  192.168.50.150  4648  alive   false   2         0.7.0+ent  dc1         global
node2.global  192.168.50.151  4648  alive   true    2         0.7.0+ent  dc1         global
node3.global  192.168.50.152  4648  alive   false   2         0.7.0+ent  dc1         global
vagrant@node1:~$ nomad node-status

ID        DC   Name   Class   Drain  Status
def34073  dc1  node1  <none>  false  ready
c4146f97  dc1  node2  <none>  false  ready
7de3fca4  dc1  node3  <none>  false  ready
```

## Step 2: Nomad plan
Use Nomad plan to invoke a dry-run of the scheduler on our job. This is similar to `terraform plan` where we can see the potential outcome of an actual job deploy beforehand.

```bash
vagrant@node1:/vagrant/application-deployment/redis$ nomad plan redis.nomad
+ Job: "example"
+ Task Group: "cache" (1 create)
  + Task: "redis" (forces create)

Scheduler dry-run:
- All tasks successfully allocated.

Job Modify Index: 0
To submit the job with version verification run:

nomad run -check-index 0 redis.nomad

When running the job with the check-index flag, the job will only be run if the
server side version matches the job modify index returned. If the index has
changed, another user has modified the job and the plan's results are
potentially invalid.
```

All tasks were succesfully allocated by our dry-run. If you see errors, you might be missing the docker driver or do not have enough capacity on your nodes.

## Step 3: Nomad run

Now deploy the job

```bash
vagrant@node1:/vagrant/application-deployment/redis$ nomad run redis.nomad
==> Monitoring evaluation "b8cc9e21"
    Evaluation triggered by job "example"
    Allocation "9cb8644e" created: node "c4146f97", group "cache"
    Evaluation within deployment: "f09558a8"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "b8cc9e21" finished with status "complete"
```
Nomad first created an evaulation to determine if a new job needs to be allocated. Once the evalaution was confirmed and a scheduler found an appropriate node to place the tasks, an allocation was created and scheduled to a Nomad client (worker node).

Inspect the status of the job:
```bash
vagrant@node1:/vagrant/application-deployment/redis$ nomad status
ID     Type     Priority  Status   Submit Date
redis  service  50        running  12/27/17 20:01:35 UTC

vagrant@node1:/vagrant/application-deployment/redis$ nomad status redis
ID            = redis
Name          = redis
Submit Date   = 12/27/17 20:01:35 UTC
Type          = service
Priority      = 50
Datacenters   = dc1
Status        = running
Periodic      = false
Parameterized = false

Summary
Task Group  Queued  Starting  Running  Failed  Complete  Lost
cache       0       0         1        0       0         0

Latest Deployment
ID          = a93eefa2
Status      = successful
Description = Deployment completed successfully

Deployed
Task Group  Desired  Placed  Healthy  Unhealthy
cache       1        1       1        0

Allocations
ID        Node ID   Task Group  Version  Desired  Status   Created At
919f7100  c4146f97  cache       0        run      running  12/27/17 20:01:35 UTC
```

An allocation represents an instance of a Task Group placed on a node. To inspect an allocation we use the alloc-status command:

```bash
vagrant@node1:/vagrant/application-deployment/redis$ nomad alloc-status 919f7100
ID                  = 919f7100
Eval ID             = 9be6a36f
Name                = redis.cache[0]
Node ID             = c4146f97
Job ID              = redis
Job Version         = 0
Client Status       = running
Client Description  = <none>
Desired Status      = run
Desired Description = <none>
Created At          = 12/27/17 20:01:35 UTC
Deployment ID       = a93eefa2
Deployment Health   = healthy

Task "redis" is "running"
Task Resources
CPU        Memory           Disk     IOPS  Addresses
2/500 MHz  6.3 MiB/256 MiB  300 MiB  0     db: 10.0.2.15:27096

Task Events:
Started At     = 12/27/17 20:01:36 UTC
Finished At    = N/A
Total Restarts = 0
Last Restart   = N/A

Recent Events:
Time                   Type        Description
12/27/17 20:01:36 UTC  Started     Task started by client
12/27/17 20:01:35 UTC  Task Setup  Building Task Directory
12/27/17 20:01:35 UTC  Received    Task received by client
```

## Step 4: Nomad logs

To see the logs of a task, we can use the logs command:
```bash
vagrant@node1:/vagrant/application-deployment/redis$ nomad logs 919f7100 redis
1:C 27 Dec 20:01:35.996 # Warning: no config file specified, using the default config. In order to specify a config file use redis-server /path/to/redis.conf
                _._
           _.-``__ ''-._
      _.-``    `.  `_.  ''-._           Redis 3.2.11 (00000000/0) 64 bit
  .-`` .-```.  ```\/    _.,_ ''-._
 (    '      ,       .-`  | `,    )     Running in standalone mode
 |`-._`-...-` __...-.``-._|'` _.-'|     Port: 6379
 |    `-._   `._    /     _.-'    |     PID: 1
  `-._    `-._  `-./  _.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |           http://redis.io
  `-._    `-._`-.__.-'_.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |
  `-._    `-._`-.__.-'_.-'    _.-'
      `-._    `-.__.-'    _.-'
          `-._        _.-'
              `-.__.-'

1:M 27 Dec 20:01:35.997 # WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.
1:M 27 Dec 20:01:35.997 # Server started, Redis version 3.2.11
1:M 27 Dec 20:01:35.997 # WARNING overcommit_memory is set to 0! Background save may fail under low memory condition. To fix this issue add 'vm.overcommit_memory = 1' to /etc/sysctl.conf and then reboot or run the command 'sysctl vm.overcommit_memory=1' for this to take effect.
1:M 27 Dec 20:01:35.997 # WARNING you have Transparent Huge Pages (THP) support enabled in your kernel. This will create latency and memory usage issues with Redis. To fix this issue run the command 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' as root, and add it to your /etc/rc.local in order to retain the setting after a reboot. Redis must be restarted after THP is disabled.
1:M 27 Dec 20:01:35.997 * The server is now ready to accept connections on port 6379
```

## Step 5: Nomad GUI
Make sure the redis job was deployed in the Nomad GUI. You will need to authenitcate using an appropriate nomad acl token.

If using this repo's vagrantfile check: http://localhost:4646/ui/jobs  (try 5646 or 6646 depending on leader)
![](https://raw.githubusercontent.com/hashicorp/nomad-guides/master/assets/Nomad_GUI_redis.png)

## Step 6: Consul GUI
See the registered tasks in the Consul GUI.

If using this repo's vagrantfile check: http://localhost:8500/ui/#/dc1/services
![](https://raw.githubusercontent.com/hashicorp/nomad-guides/master/assets/Consul_GUI_redis.png)




## Step 7: Stopping a job
Stop the job using the `nomad stop $job` command

```bash
vagrant@node1:/vagrant/application-deployment/redis$ nomad stop redis
==> Monitoring evaluation "5e329c11"
    Evaluation triggered by job "redis"
    Evaluation within deployment: "a93eefa2"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "5e329c11" finished with status "complete"
```


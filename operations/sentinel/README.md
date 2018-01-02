# Nomad + Sentinel 
The goal of this guide is to help users learn how to enable and write Sentinel policies for Nomad.

## Estimated Time to Complete
20 minutes

## Prerequisites
A Nomad cluster should be up and running with ACL's enabled. Note: An Enterprise Binary is REQUIRED to use this guide. Setup a cluster with enterprise binaries using the vagrantfile here: https://github.com/hashicorp/nomad-guides/tree/master/provision/vagrant

## Challenge
Using the Nomad scheduler gives operators and developers power to deploy and consume a company's resources. Nomad is extremely easy to configure, manage, and create job files for. As such, enterprises need guardrails around what users can deploy to ensure resources are used both safely and fairly across the organization.


## Solution
Using the combination of ACL's, Namespaces, Quotas, and Sentinel, operators can effectively limit and provide guard rails for users of Nomad. This guide will cover Sentinel.

# Steps
Before we start writing Sentinel policies, we need to create an initial bootstrap token (a management token). Note: You may have already completed this step.
## Step 1: Create Nomad ACL bootstrap token
CLI
```bash
$ nomad acl bootstrap
Accessor ID  = 28f1b26a-a566-d31b-7cc8-97eac5971b96
Secret ID    = aee01f6a-a55b-effc-0309-196734685178
Name         = Bootstrap Token
Type         = management
Global       = true
Policies     = n/a
Create Time  = 2017-10-30 14:12:22.359022939 +0000 UTC
Create Index = 14
Modify Index = 14
```
API
```bash
$ curl \
     --request POST \
     http://127.0.0.1:4646/v1/acl/bootstrap
```
Now export this nomad token as the NOMAD_TOKEN variable
```bash
$ export NOMAD_TOKEN="aee01f6a-a55b-effc-0309-196734685178"j
```

## Step 2: Write Sentinel policies
Now we can write some Sentinel policies and apply them to Nomad!

### Use Case 1: Restrict allowed driver use to Docker
This example will ensure all tasks are restricted to using Docker as their driver. Attempts to invoke isolated/raw exec, lxc, qemu, etc. will be denied.

Create a file called all_drivers_docker.sentinel (or use the file under sentinel_policies)

```bash
# all_drivers_docker.sentinel
# Test policy only allows docker based tasks
main = rule { all_drivers_docker }

# all_drivers_docker checks that all the drivers in use are exec
all_drivers_docker = rule {
	all job.task_groups as tg {
		all tg.tasks as task {
			task.driver is "docker"
		}
	}
}
```
CLI: now apply the sentinel policy to Nomad
```bash
$ nomad sentinel apply -level=soft-mandatory docker-check sentinel_policies/all_drivers_docker.sentinel;
Successfully wrote "docker-check" Sentinel policy!
```

If we try to run a job that does not use docker, we will see this failure (docs.nomad uses the 'exec' driver)

```bash
$ nomad plan jobs/docs.nomad
Error during plan: Unexpected response code: 500 (1 error(s) occurred:

* docker-check : Result: false

FALSE - docker-check:2:1 - Rule "main"
  FALSE - docker-check:6:2 - all job.task_groups as tg {
	all tg.tasks as task {
		task.driver is "docker"
	}
}

FALSE - docker-check:5:1 - Rule "all_drivers_docker"
)
```

'all' is a [universal quantifier](https://docs.hashicorp.com/sentinel/language/spec#any-all-expressions) that allows us to build a chain of 'and' logical expressions for evaluating our rules.


In this example we are building a chain of logical ```and```'s across all our tasks and ensuring that they all evaluate to true: 'they are using docker'.

### Use Case 2: Restrict allowed images to company images
First delete the old policy, we will be adding to it
```bash
$ nomad sentinel delete docker-check
```
You can extend the last policy to make sure that jobs are limited to your company's docker images (NOTE: the allowed_images search uses a regex).

```bash
#restrict_docker_images.sentinel
main = rule { all_drivers_docker and allowed_docker_images }

allowed_images = [
	"https://hub.docker.internal/",
	"https://hub-test.docker.internal/",
    #"redis", #if you want to test with 'nomad init'
]

all_drivers_docker = rule {
	all job.task_groups as tg {
		all tg.tasks as task {
			task.driver is "docker"
		}
	}
}

allowed_docker_images = rule {
	all job.task_groups as tg {
		all tg.tasks as task {
			any allowed_images as allowed {
				task.config.image matches allowed
			}
		}
	}
}
```
If job job's image name does not match the 'allowed_images' regex then the job submission will fail. 

Now apply the sentinel policy:
```bash
$ nomad sentinel apply -level=soft-mandatory docker-image-check sentinel_policies/restrict_docker_images.sentinel;
Successfully wrote "docker-image-check" Sentinel policy!
```
reminder: you can list current policies applied as well
```bash
$ nomad sentinel list
Name                Scope       Enforcement Level  Description
docker-image-check  submit-job  soft-mandatory     <none>
```
Add 'redis' to the allowed_images regex if you want to play around with pass/fails with this policy.

```bash
$ nomad plan jobs/example.nomad
Error during plan: Unexpected response code: 500 (1 error(s) occurred:

* docker-image-check : Result: false

FALSE - docker-image-check:2:1 - Rule "main"
  TRUE - docker-image-check:2:15 - all_drivers_docker
    TRUE - docker-image-check:11:2 - all job.task_groups as tg {
	all tg.tasks as task {
		task.driver is "docker"
	}
}
  FALSE - docker-image-check:2:38 - allowed_docker_images
    FALSE - docker-image-check:19:2 - all job.task_groups as tg {
	all tg.tasks as task {
		any allowed_images as allowed {
			task.config.image matches allowed
		}
	}
}

TRUE - docker-image-check:10:1 - Rule "all_drivers_docker"

FALSE - docker-image-check:18:1 - Rule "allowed_docker_images"
)
```

if you add 'redis' to the allowed images then you should pass when using the jobs/example.nomad file.

```bash
$ nomad plan jobs/example.nomad
+ Job: "example"
+ Task Group: "cache" (4 create)
  + Task: "redis" (forces create)

Scheduler dry-run:
- All tasks successfully allocated.

```

```bash
$ nomad sentinel delete docker-image-check
```

### Use Case 3: Restrict resource usage per job

We can leverage Sentinel to enforce resource limits on jobs submitted by users. In this example we will use Sentinel functions when evaluating our rules. Functions are great when we need to use loops and 'if' statements in our Sentinel policies.

```bash
resource_check = func(task_groups, resource) {
  result = 0
  for task_groups as g {
    for g.tasks as t {
        # Multiply the task resources by the number of tasks in the group
        result = result + t.resources[resource] * g.count
    }
  }
  return result
}

main = rule  {
  resource_check(job.task_groups, "cpu") <= 1500 and
  resource_check(job.task_groups, "memory_mb") <= 2500
}
```
Now apply the policy

```bash
$ nomad sentinel apply -level=soft-mandatory resource-check sentinel_policies/resource_check.sentinel;
Successfully wrote "resource-check" Sentinel policy!
```
if you bump the count from 3 to 4 or increase the task resource usage of your job you should see a failure like so
```bash
$ nomad plan jobs/example.nomad
Error during plan: Unexpected response code: 500 (1 error(s) occurred:

* resource-check : Result: false

FALSE - resource-check:13:1 - Rule "main"
  FALSE - resource-check:14:3 - resource_check(job.task_groups, "cpu") <= 1500
)
```
Otherwise it should pass. There is also an example job with two groups called `jobs/example_two_groups.nomad` that you can use to test resource usage with multiple task groups.

### Use Case 4: Restrict Batch jobs to business hours

```bash
import "time"

batch_job = rule {
	job.type is "batch"
}

is_weekday = rule { time.day not in ["saturday", "sunday"] }
is_open_hours = rule { time.hour > 8 and time.hour < 16 }

main = rule { is_open_hours and is_weekday and batch_job }
```

```bash
$ nomad sentinel apply -level=soft-mandatory batch-business-hours sentinel_policies/restrict_batch_deploy_time.sentinel
```

### Use Case 5: Enforce multi-datacenter job deployments
```bash
main = rule { enforce_multi_dc }

enforce_multi_dc = rule {
  length(job.datacenters) > 1
}
```

### Useful tips
Use ```$ nomad inspect $job``` or ```$ nomad run -output my-job.nomad``` to see the output of a Nomad job in json. This is a great way to see info you have to work with in Sentinel. Also make use of the ```print()``` function.

```bash
$ nomad inspect example
{
    "Job": {
        "AllAtOnce": false,
        "Constraints": null,
        "CreateIndex": 40,
        "Datacenters": [
            "dc1"
        ],
        "ID": "example",
        "JobModifyIndex": 903,
        "Meta": null,
        "ModifyIndex": 905,
        "Name": "example",
        "Namespace": "default",
        "ParameterizedJob": null,
        "ParentID": "",
        "Payload": null,
        "Periodic": null,
        "Priority": 50,
        "Region": "global",
        "Stable": false,
        "Status": "running",
        "StatusDescription": "",
        "Stop": false,
        "SubmitTime": 1509141394222929010,
        "TaskGroups": [
            {
                "Constraints": null,
                "Count": 2,
                "EphemeralDisk": {
                    "Migrate": false,
                    "SizeMB": 300,
                    "Sticky": false
                },
                "Meta": null,
                "Name": "cache",
                "RestartPolicy": {
                    "Attempts": 10,
                    "Delay": 25000000000,
                    "Interval": 300000000000,
                    "Mode": "delay"
                },
                "Tasks": [
                    {
                        "Artifacts": null,
                        "Config": {
                            "port_map": [
                                {
                                    "db": 6379.0
                                }
                            ],
                            "image": "redis:3.2"
                        },
                        "Constraints": null,
                        "DispatchPayload": null,
                        "Driver": "docker",
                        "Env": null,
                        "KillTimeout": 5000000000,
                        "Leader": false,
                        "LogConfig": {
                            "MaxFileSizeMB": 10,
                            "MaxFiles": 10
                        },
                        "Meta": null,
                        "Name": "redis",
                        "Resources": {
                            "CPU": 500,
                            "DiskMB": 0,
                            "IOPS": 0,
                            "MemoryMB": 256,
                            "Networks": [
                                {
                                    "CIDR": "",
                                    "Device": "",
                                    "DynamicPorts": [
                                        {
                                            "Label": "db",
                                            "Value": 0
                                        }
                                    ],
                                    "IP": "",
                                    "MBits": 10,
                                    "ReservedPorts": null
                                }
                            ]
                        },
                        "Services": [
                            {
                                "AddressMode": "auto",
                                "CheckRestart": null,
                                "Checks": [
                                    {
                                        "Args": null,
                                        "CheckRestart": null,
                                        "Command": "",
                                        "Header": null,
                                        "Id": "",
                                        "InitialStatus": "",
                                        "Interval": 10000000000,
                                        "Method": "",
                                        "Name": "alive",
                                        "Path": "",
                                        "PortLabel": "",
                                        "Protocol": "",
                                        "TLSSkipVerify": false,
                                        "Timeout": 2000000000,
                                        "Type": "tcp"
                                    }
                                ],
                                "Id": "",
                                "Name": "global-redis-check",
                                "PortLabel": "db",
                                "Tags": [
                                    "global",
                                    "cache"
                                ]
                            }
                        ],
                        "ShutdownDelay": 0,
                        "Templates": null,
                        "User": "",
                        "Vault": null
                    }
                ],
                "Update": {
                    "AutoRevert": false,
                    "Canary": 0,
                    "HealthCheck": "checks",
                    "HealthyDeadline": 180000000000,
                    "MaxParallel": 1,
                    "MinHealthyTime": 10000000000,
                    "Stagger": 30000000000
                }
            }
        ],
        "Type": "service",
        "Update": {
            "AutoRevert": false,
            "Canary": 0,
            "HealthCheck": "",
            "HealthyDeadline": 0,
            "MaxParallel": 1,
            "MinHealthyTime": 0,
            "Stagger": 30000000000
        },
        "VaultToken": "",
        "Version": 7
    }
}
```
# Running the Nomad Multi-Job Demo
The Nomad Multi-Job Demo shows off some of Nomad Enterprise's features including [Namespaces](https://www.nomadproject.io/guides/security/namespaces.html), [Resource Quotas](https://www.nomadproject.io/guides/security/quotas.html), and [Sentinel Policies](https://www.nomadproject.io/guides/security/sentinel-policy.html). It also uses Nomad [ACLs](https://www.nomadproject.io/guides/security/acl.html), which are not a Nomad Enterprise feature but are applicable to namespaces and resource quotas and are required for using Nomad Sentinel policies.

Note that you must have AWS keys which allow you to download the Nomad Enterprise binary from AWS S3. These can be requested by contacting [HashiCorp Sales](https://www.hashicorp.com/go/contact-sales).

## Reference Material

The instructions below describe how you can run and connect the Nomad Multi-Job Demo in AWS using [Nomad](https://www.nomadproject.io/) and [Consul](https://www.consul.io). The latter is commonly deployed with Nomad; in this demo, it is only used to help bootstrap the Nomad cluster. Additionally, [Packer](https://www.packer.io) was used to build the AWS AMI that runs Nomad and Consul, while [Terraform](https://www.terraform.io) is used to provision the AWS infrastructure (including a VPC and public subnet and EC2 instances).

## Estimated Time to Complete
60 minutes

## Personas
Our target persona is a an operations engineer who wants to help multiple teams run multiple jobs in a single Nomad cluster while isolating the jobs of these teams with Nomad namespaces and ensuring that no team over-uses the resources of the cluster.

## Challenge
Docker containers, Java applications, and other technologies can be run by Nomad, but when multiple teams share a cluster, some controls are needed to avoid one team's jobs having an adverse impact on the jobs of other teams.

## Solution

This guide illustrates how Nomad can schedule Docker containers for multiple teams in isolated namespaces, use resource quotas to ensure that no team uses excessive CPU or memory from the shared cluster, and apply Sentinel policies to restrict which Nomad drivers and Docker images can be used.

## Prerequisites
In order to deploy the demo to AWS, you will need an AWS account. You will also need AWS access and secret access [keys](http://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys) for provisioning resources into your own AWS account as well as a second set of AWS keys provided by HashiCorp for downloading the Nomad Enterprise binary from AWS S3. You'll also need a [key pair](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2-key-pairs.html) from your AWS account.

If you want to customize the AMI used by the demo, you will need to download and install Packer locally from [Packer Downloads](https://www.packer.io/downloads.html). You can use Terraform Enterprise or open source Terraform to provision the AWS infrastructure the demo runs on. If you want to use open source Terraform, install it from [Terraform Downloads](https://www.terraform.io/downloads.html). This demo was built and tested with Packer 1.3.2 and Terraform 0.11.10.

## Steps
Please execute the following commands and instructions to deploy the AWS infrastructure and run the catalogue microservices with Nomad.

## Step 1: Create a New AMI with Packer (optional)
You can now use Packer and Terraform to provision your AWS EC2 instances along with other AWS infrastructure.

We have already used Packer to create Amazon Machine Image ami-06f5d536610fcbd6c which uses Nomad Enterprise 0.8.6 and Consul 1.3.0. However, this is a private AMI that is only visible within the HashiCorp hc-se-demos-2018 AWS account. HashiCorp SEs and other HashiCorp employees with access to that AWS account can use this AMI in the AWS us-east-1 region.

Readers without access to the hc-se-demos-2018 AWS account or who want to deploy the demo in a different AWS region or make changes to any of the files in the shared directory will need to use Packer to build their own AMI. Please do not build a public image with the Nomad Enterprise binary. Doing so violates your license agreement with HashiCorp.

As mentioned in the introduction above, you must have AWS keys which allow you to download the Nomad Enterprise binary from AWS S3. These can be requested by contacting [HashiCorp Sales](https://www.hashicorp.com/go/contact-sales).

Building a new AMI with Packer is very simple. Starting from the home directory, do the following (being sure to specify the region and a vaid source_ami for that region in packer.json if the region is different from us-east-1).  The environment variables starting with "AWS" are the AWS keys for your own AWS account that will allow you to provision AWS resources like a VPC, subnets, security groups, IAM roles and policies, and EC2 instances.  The environment variables starting with "S3" are they AWS keys provided by HashiCorp which allow the Nomad Enterprise binary to be downloaded from S3 with the AWS CLI. The S3 keys are only needed by Packer to build the AMI and are not needed when running Terraform.

```
export AWS_ACCESS_KEY_ID=<access_key_for_your_aws_account>
export AWS_SECRET_ACCESS_KEY=<secret_key_for_your_aws_account>
export S3_AWS_ACCESS_KEY_ID=<access_key_for_nomad_download_from_s3>
export S3_AWS_SECRET_ACCESS_KEY=<secret_key_for_nomad_download_from_s3>
cd aws/packer
packer build packer.json
cd ..
```

Be sure to note the AMI ID of your new AMI. You will need to enter this in your Terraform variables in Step 4. If you generated this in a region other than us-east-1, then be sure to set the region variable in Step 4.

## Step 2: Create an AWS EC2 Key Pair (if needed)
You need to use one of your AWS EC2 key pairs or [create](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2-key-pairs.html#having-EC2-create-your-key-pair) a new one. Please download your private key and copy it to the aws directory to make connecting to your EC2 instances easier in Step 6.

## Step 3: Set Up and Configure Terraform Enterprise (optional)
1. If you do not already have a Terraform Enterprise (TFE) account, self-register for an evaluation at https://app.terraform.io/account/new.
1. After getting access to your TFE account, create an organization for yourself. You might also want to review the [Getting Started](https://www.terraform.io/docs/enterprise/getting-started/index.html) documentation.
1. Connect your TFE organization to GitHub. See the [Configuring Github Access](https://www.terraform.io/docs/enterprise/vcs/github.html) documentation.

If you want to use open source Terraform instead of TFE, you can fork this repository locally, create a copy of the included terraform.tfvars.example file, calling it terraform.tfvars, set values for the variables in it as directed in Step 4, run `terraform init`, and then run `terraform apply`. Note that you should not provide a value for bootstrap_token at this time.

## Step 4: Configure a Terraform Enterprise Workspace
1. Fork this repository by clicking the Fork button in the upper right corner of the screen and selecting your own personal GitHub account or organization.
1. Create a workspace in your TFE organization called nomad-multi-job-demo.
1. Configure the workspace to connect to the fork of this repository in your own Github account.
1. Set the Terraform Working Directory to "operations/multi-job-demo/aws".
1. On the Variables tab of your workspace, add Terraform variables as described below.
1. If you used Packer to build a new AMI, set the ami variable to the AMI ID of the new AMI; otherwise, you can use the default value. If you built your AMI in a region different from us-east-1, then set the region variable to that region and set the subnet_az variable to an availability zone in that region.
1. Set the key_name variable to the name of your private key and set the private_key_data variable to the contents of the private key. Be sure to mark the private_key_data variable as sensitive.
1. Set the variables name_tag_prefix and cluster_tag_value to something like "\<your_name\>-nomad-multi-job-demo".
1. HashiCorp SEs should also set the owner and ttl variables which are used by the AWS Lambda reaper function that terminates old EC2 instances.
1. Set the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables to the AWS access and secret keys for your AWS account. Note that you do not need the AWS S3 keys that were used to download the Nomad Enterprise binary while building the AMI with Packer.

Now, you're ready to use Terraform to provision your EC2 instances with the Nomad and Consul servers and clients.  The default configuration creates 1 server instance running Nomad and Consul servers and 3 client instances running Nomad and Consul clients.

If desired, you can set the vpc_cidr and subnet_cidr to valid CIDR ranges. The defaults are "10.0.0.0/16" and "10.0.1.0/24" respectively.

## Step 5: Provision the Nomad Multi-Job Demo
1. Click the "Queue Plan" button in the upper right corner of your workspace.
1. On the Current Run tab, you should see a new run. If the plan succeeds, you can view the plan and verify that the AWS infrastructure including the Nomad/Consul server and clients will be created when you apply your plan.
1. Click the "Confirm and Apply" button to actually provision everything.

When the apply finishes, you should see a message giving the public and private IP addresses for your server and client instances along with a command to ssh to your server and URLs to access the Nomad and Consul UIs. You will also see a bootstrap Nomad ACL token that grants full Nomad access and dev and qa tokens with more limited permissions. In your AWS console, you should be able to see all your instances under EC2 Instances. If you were already on that screen, you'll need to refresh it.

Note that Nomad and Consul will automatically be started and automatically joined into a cluster spanning all the provisioned instances.

## Step 6: Connect to the Nomad Server
From a directory containing your private EC2 key pair, you can connect to your Nomad server with `ssh -i <key> ubuntu@<server_public_ip>`, replacing \<key\> with your actual private key file (ending in ".pem") and \<server_public_ip\> with the public IP of your server instance. The exact command should have been in the outputs of the apply. (Note that the AWS Console will erroneously suggest that you use "root" as the username instead of "ubuntu" when connecting.)

After connecting, if you run the `pwd` command, you will see that you are in the /home/ubuntu directory. If you run the `ls` command, you should see several Nomad job files and the bootstrap.txt file which contains the Nomad ACL bootstrap token. If you run `env | grep NOMAD`, you will see that the NOMAD_ADDR environment varialbe has been set.

Verify that Nomad is running with `ps -ef | grep nomad`. You should see "/usr/local/bin/nomad agent -config=/etc/nomad.d/nomad.hcl".

## Step 7: Access the Nomad UI
You can connect to the Nomad UI with a browser using the URL included in the Terraform outputs. Initially, there will not be any jobs running, but you should be able to see Clients and Servers even without entering an ACL token. That is because Terraform created an [anonymous](./aws/acls/anonymous.hcl) ACL policy that allows users without tokens to list jobs and read agents and nodes. Terraform also created [dev](./aws/acls/dev.hcl) and [qa](./aws/acls/qa.hcl) ACL policies. If you select one of the clients, you will see information about it including that it has cpu.totalcompute of 4600 and memory.totalbytes of 4142092288 (representing close to 4GB), that the exec, java, and docker drivers are all enabled, and that Java and Docker are installed.

## Step 8: Set Nomad ACL Tokens
You will want to set Nomad ACL tokens both in the Nomad UI and in your SSH session. In the Nomad UI, click on the "ACL Tokens" link in the upper right corner, copy the Nomad bootstrap token from the Terraform outputs into the Secret ID field, and click the "Set Token" button. You will now be able to see everything in the Nomad UI in all namespaces.

In your SSH session connected to the Nomad server, run the command `export NOMAD_TOKEN=<bootstrap_token>` where "\<bootstrap_token\>" is the same bootstrap token you just entered in the Nomad UI. This will give you full access to all Nomad CLI commands in the current session unless you change NOMAD_TOKEN to a more restrictive token.

You could also examine the bootstrap token by running `nomad acl token self`. This will show you that the token is a management token and does not have any policies associated with it; that is because management tokens are unrestricted.

## Step 9: Explore Namespaces and Quotas
Nomad [namespaces](https://www.nomadproject.io/guides/security/namespaces.html) allow a single Nomad cluster to be shared by multiple teams and projects. Jobs can be segmented from each other so that multiple teams can use the same job IDs without conflict. Additionally, [resource quotas](https://www.nomadproject.io/guides/security/quotas.html) can be attached to namespaces in order to restrict the cluster resources they can use.

Each Nomad Enterprise cluster has a default namespace, but our Terraform code added dev and qa namespaces.  To see them, in your SSH session connected to the Nomad server, run `nomad namespace list`. To get details about them, run `nomad namespace status default`, `nomad namespace status dev` and `nomad namespace status qa`. Note that all three namespaces have resource quotas with the same names attached, limiting each namespace to 4,600 MHz of CPU and 4,100 MB of memory. Effectively, each namespace is limited in this case to total consumption of one of the three clients, but its usage of resources could be spread across the clients. Since no jobs are running yet, all three namespaces will show none of their quota being used.

To see the list of all resource quotas, run `nomad quota list`. You can get more details about the quotas including current usage by running commands like `nomad quota inspect dev` or `nomad quota inspect qa`.

## Step 10: Explore Sentinel Policies
Another Nomad Enterprise feature is [Sentinel Policies](https://www.nomadproject.io/guides/security/sentinel-policy.html) which restrict the jobs that can be run in various ways. Note that Sentinel policies are always applied across all namespaces.

Terraform created the following three Sentinel policies:
1. [allow-docker-or-java-driver](./aws/sentinel/allow-docker-and-java-drivers.sentinel): only allows the Docker and Java drivers to be used to run jobs.
1. [restrict-docker-images](./aws/sentinel/restrict-docker-images.sentinel): only allows nginx and mongo images and requires that they have tags.
1. [prevent-docker-host-network](./aws/sentinel/prevent-docker-host-network.sentinel): forbids docker containers from using the host network. Instead, they must use the default bridge network or a custom overlay network.

To see the list of Sentinel policies in your SSH session attached to your Nomad server, run `nomad sentinel list`. To get more details about one of them, run `nomad sentinel read <policy>`. You will see the name, scope, enforcement level, description, and the policy itself which consists of rules that return boolean expressions. Every Sentinel policy has to have a rule called "main" which must return "true" in order for a submitted job to pass the policy. Note that soft-mandatory Sentinel policies can be overridden when running jobs if the `-policy-override` option is added. Hard-mandatory Sentinel policies cannot be overridden.

## Step 11: Run Some Jobs that Violate Sentinel Policies
You can now try to run some jobs in the default namespace and see which ones Sentinel allows.

### Step 11.a: Try to Run a Job with a Forbidden Driver
Let's start with the sleep.nomad job. If you use `cat` or `vi` to look at this job, you will see that it uses the exec driver which is not allowed. Try to run it anyway with `nomad job run sleep.nomad`.

You will see the following output:
```
Error submitting job: Unexpected response code: 500 (1 error(s) occurred:

* allow-docker-or-java-driver : Result: false

Description: Only allow Docker and Java drivers

FALSE - docker-or-java-driver:13:1 - Rule "main"
  FALSE - docker-or-java-driver:5:3 - all job.task_groups as tg {
	all tg.tasks as task {
		task.driver in ["docker", "java"]
	}
}

FALSE - allow-docker-or-java-driver:4:1 - Rule "allow_docker_and_java"
)
```
This shows that the allow-docker-or-java-driver policy prevented the job from running since it tried to use the exec driver.  Since that policy is a hard-mandatory policy, we cannot override it.

### Step 11.b: Try to Run Docker Containers that Use the Host Network
Now, let's try to run the catalogue.nomad job. If you look at the file, you will see that it runs two docker containers, which is fine; but it tries to run them with `network_mode = "host"` which violates our third Sentinel policy. Try running it with `nomad job run catalogue.nomad`. You will get the following output which will be colored red:
```
Error submitting job: Unexpected response code: 500 (1 error(s) occurred:

* prevent-docker-host-network : Result: false

FALSE - prevent-docker-host-network:11:1 - Rule "main"
  FALSE - prevent-docker-host-network:3:3 - all job.task_groups as tg {
	all tg.tasks as task {
		(task.config.network_mode is not "host") else true
	}
}

FALSE - prevent-docker-host-network:2:1 - Rule "prevent_host_network"
)
```
Since the prevent-docker-host-network policy is soft-mandatory, we can override it by running `nomad job run -policy-override catalogue.nomad`. We still see output about the policy being violated, but it is colored yellow. After that, we see that the job has been evaluated and deployed. You can actually see that it was deployed in the Nomad UI. Since you set the bootstrap token in the UI, you can click on the job and drill into it to get more details about its deployment. Note that it is running in the Default namespace. (You might have to refresh your browser to see the namespace selector show up in the upper left corner of the screen.)

### Step 11.c: Try to Run a Job with Invalid Docker Images
Now, let's try to run a web server with the webserver-test.nomad job specification file. Near the top of this file, we see that it is configured to use the "qa" namespace. While we could run this job with the bootstrap token that we already exported, let's illustrate what happens when people with more restricted tokens try to run it.

#### Step 11.c.1: Try to Run the Job as Alice
In your Terraform outputs, you should see tokens for "Alice (dev)" and "Bob (qa)".  Let's first export Alice's token to show that she cannot launch a job in the qa namespace. Run `export NOMAD_TOKEN=<alice_token>` where "\<alice_token\>" is Alice's token. (Use the token, not the accessor which is on the line below the token.) Let's also check out her token by running `nomad acl token self`.  You will see the token itself (its secret ID), its accessor ID, and that it is associated with the dev ACL policy. (Note that ACL policies are different from Sentinel policies.)

To see the dev ACL policy associated with Alice's token, run `nomad acl policy info dev`. This will show you:
```
Name        = dev
Description = access for users with dev ACL tokens
Rules       = namespace "default" {
  capabilities = ["list-jobs"]
}

namespace "dev" {
  policy = "write"
}

agent {
  policy = "read"
}

node {
  policy = "read"
}
```
While this policy allows Alice to run jobs in the dev namespace, it does not allow her to run them in the default or qa namespaces.

Now, try to run the job as Alice with `nomad job run webserver-test.nomad`. You should see `Error submitting job: Unexpected response code: 403 (Permission denied)`.  Note that the Sentinel policies were not even applied since Nomad's ACL system blocked Alice from running the job first.

#### Step 11.c.2: Try to Run the Job as Bob
Let's see if Bob can launch the job with his token. Run `export NOMAD_TOKEN=<bob_token>` where "\<bob_token\>" is Bob's token. Let's also check out his token by running `nomad acl token self`.  You will see the token itself (its secret ID), its accessor ID, and that it is associated with the qa ACL policy.

Edit the webserver-test.nomad file and pay close attention to the task specification which starts with this:
```
task "webserver" {
  driver = "docker"

  config {
    # "httpd" is not an allowed image
    image = "httpd"
```
The image has been set to "httpd" which is the name of the standard Apache webserver Docker image, but this is not one of the images allowed by the restrict-docker-images policy which has the following:
```
# Allowed Docker images
allowed_images = [
  "nginx",
  "mongo",
]

# Restrict allowed Docker images
restrict_images = rule {
  all job.task_groups as tg {
    all tg.tasks as task {
      any allowed_images as allowed {
        # Note that we require ":" and a tag after it
        # which must start with a number, preventing "latest"
        task.config.image matches allowed + ":[0-9](.*)"
      }
    }
  }
}
```

Try to run the job with Bob's token anyway, using `nomad job run webserver-test.nomad`. This time, we do not get the "403 (Permission denied)" error since Bob **is** allowed to run jobs in the qa namespace, but we do see that the restrict-docker-images Sentinel policy failed.

Since the restrict-docker-images policy is soft-mandatory, Bob could override it with the `-policy-override` option.  But being a good employee, Bob decides to edit the job specification file to use the nginx webserver instead of Apache httpd. So, go ahead and edit the webserver-test.nomad file for Bob, replacing "httpd" with "nginx" and saving the file.

Then try running `nomad job run webserver-test.nomad` again. Unfortunately, we get the same Sentinel policy failure as before. What went wrong? If you look at the restrict-docker-images policy more closely, you will see that it requires that the image name actually match a regex expression consisting of "nginx" or "mongo" followed by ":" and at least one number, possibly followed by other characters (`task.config.image matches allowed + ":[0-9](.*)"`). Effectively, the policy is requiring that all Docker images include a tag that starts with a number which precludes the use of "latest". This avoids nasty surprises when Docker images are modified.

So, let's edit the webserver-test.nomad file once more, changing the image from "nginx" to "nginx:1.15.6", saving the file, and re-running the job.  This time, the job should be run successfully.

If you look at the jobs in the Nomad UI, you won't see it if you are still looking at the default namespace. But if you select the qa namespace, you should see the webserver-test job running.

This step of the guide has shown how Sentinel policies allow Nomad administrators to impose governance restrictions on the jobs that are run by Nomad. In particular, the three policies we used restricted jobs to using the Docker and Java Nomad drivers and restricted the Docker containers to use specific images and docker network options.

## Step 12: Run a Website Job in the dev Namespace
Next, we will run some additional jobs in the dev and qa namespaces and see how the resource quotas associated with those namespaces prevent one group from hogging the cluster's resources.

In your SSH session for your Nomad server, set your NOMAD_TOKEN to Alice's token using the same `export NOMAD_TOKEN=<alice_token>` that you used earlier.  Remember that her token is associated with the dev policy.

Let's look at the dev quota again with `nomad quota status dev`. We see the following:
```
Name        = dev
Description = dev quota
Limits      = 1

Quota Limits
Region  CPU Usage  Memory Usage
global  0 / 4600   0 / 4096
```

Let's also look at the website-dev.nomad job specification file. The job is broken up into "nginx" and "mongodb" groups which each have have one task ("nginx" or "mongodb") which would consume 500 MHz of CPU and 512 MB of memory. But the job specifies `count = 2` for both groups, so it will actually consume 2,000 MHz of CPU and 2,048 MB of memory if Nomad is able to schedule all four tasks.  Since there are currently no jobs running in the dev namespace, Nomad should be able to run the entire job.

So, run the job for Alice with the command `nomad job run website-dev.nomad`. As expected, the job does run and no Sentinel policy violations are reported.

In the Nomad UI, click on the ACL Tokens link, replace the bootstrap token in the Secret ID field with Alice's token, and click the "Set Token" button. You should see Alice's token and the dev policy listed below it, but you might have to refresh your browser or first clear the token before setting.  At this point, if you (pretending to be Alice) click on the catalogue job that is still running in the default namespace, you will see a "Not Authorized" page since Alice can only list jobs in the default namespace.

Use your browser's back arrow control and refresh the page. Then, change the namespace to "dev".  You should be able to drill into the website job. In particular, you should see that there are 2 mongodb and 2 nginx task groups running as desired.

In your SSH session, you can examine the dev quota again with `nomad quota status dev` or `nomad quota inspect dev`. The first includes:
```
Quota Limits
Region  CPU Usage    Memory Usage
global  2000 / 4600  2048 / 4096
```
which shows that the job has reserved the exact amount of CPU and memory that we calculated. (Note that the actual memory consumption could be lower.) The second command gives more details about the current utilization of the resource quota.

## Step 13: Run a Website Job in the qa Namespace
If you run the `ls` command, you'll se that we have two similar policies, "website-dev.nomad" and "website-qa.nomad". These are mostly identical with the key differences being the namespace that is specified and the Consul tags.  Note in particular that the job names at the top of the files are identical. Without namespaces, if the dev and qa teams tried to run these jobs on a single Nomad cluster, the second job would be prevented from running since job names must be unique within a single namespace. But since these jobs will be run in different namespaces, it's ok for them to use the same job name.

Let's try to have Bob run the website-qa.nomad job. We'll first need to set the NOMAD_TOKEN to his token as we did before: `export NOMAD_TOKEN=<bob_token>`. Let's also set his token in the UI so we can see what happens there after you run the job in the qa namespace as Bob. When you set his token in the UI, you should see the qa policy listed. Change the namespace to "qa" and note that the webserver-test job is still running.

In fact, if you run `nomad quota status qa` in your SSH session, you'll see the following quota limit
```
Quota Limits
Region  CPU Usage    Memory Usage
global  1000 / 4600  1024 / 4096
```
which indicates that the webserver-test job has reserved 1,000 MHz of CPU and 1,024 MB of memory.

Edit the website-qa.nomad file and observe that it is configured to run two nginx and two mongodb groups, just like the website-dev.job that Alice ran.  However, the QA team has configured each task in their job to use 1,024 MB of memory which means it needs a total of 4,096 MB of memory. But since the webserver-test job is already using 1,024 MB of memory, running all the groups in the website-qa.nomad job would exceed the quota of the qa namespace.

Even so, let's try to run the job with `nomad job run website-qa.nomad`. Nomad gives us the following output:
```
==> Monitoring evaluation "c8c2c2d0"
    Evaluation triggered by job "website"
    Evaluation within deployment: "8665b490"
    Allocation "8dd94981" created: node "912eb1e0", group "nginx"
    Allocation "9f3aab82" created: node "912eb1e0", group "mongodb"
    Allocation "e014cf08" created: node "80c8e900", group "nginx"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "c8c2c2d0" finished with status "complete" but failed to place all allocations:
    Task Group "mongodb" (failed to place 1 allocation):
      * Quota limit hit "memory exhausted (5120 needed > 4096 limit)"
    Evaluation "230070e7" waiting for additional capacity to place remainder
```
In the Nomad UI, if you select the website job in the qa namespace, you will see that 3 allocations are running but 1 is queued. You'll also see a red banner message reporting that one mongodb allocation could not be placed because of a quota limit.

(The actual results can currently be inconsistent. Sometimes, two of the four allocations are not run even though there should be enough memory left for one of them. This seems to depend on which agents the other jobs were scheduled on.)

It is important to note that the fourth group from the website-qa.nomad job was not rejected but was queued. This means that if the QA team (meaning Bob) stops some other job in the qa namespace, Nomad will schedule the fourth group (the missing mongodb allocation).

So, in the Nomad UI, click the Jobs link at the top of the screen so that we see both the website and the webserver-test jobs in the qa namespace. Select the latter and click the Stop button. Also click the "Yes, Stop" button to really stop the job. Click the Jobs link again and then click the website job. It now shows 4 running allocations, showing that Nomad did schedule the missing mongodb allocation.

Back in your SSH session, run `nomad quota status qa` one last time which will give you:
```
Quota Limits
Region  CPU Usage    Memory Usage
global  2000 / 4600  4096 / 4096
```

## Some Comments About Namespaces and Quotas
It is worth pointing out that our Nomad cluster had enough memory on the 3 clients to have run both the website and the webserver-test jobs in the qa namespace along with the website job in the dev namespace and the catalogue job in the default namespace. But if Nomad had allowed the QA team to run both the website and webserver-test jobs in the qa namespace, the dev team might have been adversely affected when they later tried to run some other jobs.  In our case, the namespaces and quotas did what they were supposed to do: prevent the QA team from using more resources on the cluster than it had been allocated.

Note that the QA team could do either of the following if it wanted to use more than its current quota temporarly:
1. Ask a Nomad administrator to run one of their jobs (probably the smaller webserver-test.nomad job) in the default namespace.
1. Ask a Nomad administrator to temporarily increase the qa quota.

## Cleanup
If you are using Terraform OSS, please do the following:
1. Run `export TF_WARN_OUTPUT_ERRORS=1` to suppress errors related to outputs for the nomadconsul module during the destroy.
1. Run `terraform destroy` to destroy the provisioned infrastructure.

If you are using Terraform Enterprise, do the following instead:
1. Add the environment variable CONFIRM_DESTROY=1 (which is needed to destroy infrastructure in TFE) to your workspace.
1. Add the environment variable TF_WARN_OUTPUT_ERRORS=1 to your workspace to suppress errors related to outputs for the nomadconsul module during the destroy.
1. In the TFE UI, go to the Settings tab of your workspace and then click the "Queue destroy Plan" button.  Then confirm that you want to destroy when the run reaches the Apply stage of the run.

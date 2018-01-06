# Golang Application + Dynamic Database Credentials (MySQL) 
This guide will discuss native app library integration and dynamic database credentials with Nomad, Vault, and MySQL. It will also show revoking those dynamic database credentials with Vault's GUI.

#### TLDR;
Using Vagrantfile setup:
```bash
vagrant@node1:/vagrant/vault-examples/goapp$ ./golang_vault_setup.sh

vagrant@node1:/vagrant/vault-examples/goapp$ nomad run application.nomad

vagrant@node1:/vagrant/vault-examples/goapp$ nomad status app

#Pull an alloc id from status, logs show dynamic username password
vagrant@node1:/vagrant/vault-examples/goapp$ nomad logs -stderr 435bf5cd
. . .
2018/01/04 20:28:49 username v-read-40xpu913r, password A1a-73r2ywpqx6wrqqts

#On Node3 
vagrant@node3:~$ mysql -h 192.168.50.152 -u vaultadmin -pvaultadminpassword
MariaDB [(none)]> SELECT User FROM mysql.user;
+------------------+
| User             |
+------------------+
| v-read-40xpu913r |
| v-read-q5sr6rzrz |
| v-read-xr3v2yrsr |
| vaultadmin       |
| root             |
+------------------+

#login to Vault GUI
username: vault   password: vault
http://localhost:8200/ui/vault/auth?with=userpass

#revoke database credentials:
http://localhost:8200/ui/vault/leases/list/mysql/creds/app/

#Show database users/passwords deleted in mysql
MariaDB [(none)]> SELECT User FROM mysql.user;
+------------+
| User       |
+------------+
| vaultadmin |
| root       |
+------------+

#Optional: App output is simple, you can check in browser as well http://localhost:8080
vagrant@node1:/vagrant/vault-examples/goapp$ curl http://10.0.2.15:8080
{"message":"Hello"}
```

## Estimated Time to Complete
20 minutes

## Prerequisites
A Nomad cluster should be up and running. Setup a cluster with OSS or enterprise binaries using the vagrantfile here: https://github.com/hashicorp/nomad-guides/tree/master/provision/vagrant

A MySQL server should be available (the vagrantfile above automatically stands up a MySQL database).

A Vault server should be available and Nomad should be configured to talk to and create tokens with Vault (the vagrantfile above installs Vault and configures the Nomad integration automatically). More details here:
https://www.nomadproject.io/docs/agent/configuration/vault.html
https://www.nomadproject.io/docs/vault-integration/index.html

## Challenge
Many workloads require access to tokens, passwords, certificates, API keys, and other secrets. Deploying these initial secrets is a challenging problem known as 'secure introduction'.

Another key challenge is secret lifecycle management. If secrets are exposed or compromised, how do we stop the bleeding? Vault's dynamic secret backends generate secrets with short time to lives through leases. Those leases can also be manually revoked before their expiration in the event of a break glass scenario (exposure/compromise). In a database example, a revoked secret lease will cause Vault to delete the assosciated username/password from the database.

## Solution
To enable secure, auditable and easy access to your secrets, Nomad integrates with HashiCorp's Vault. Nomad servers and clients coordinate with Vault to derive a Vault token that has access to only the Vault policies the tasks need. Nomad clients make the token available to the task and handle the tokens renewal. Further, Nomad's template block can retrieve secrets from Vault making it easier than ever to secure your infrastructure.

## Nomad-Vault Architecture
1. Nomad server asks for and receives wrapped token (from Vault) scoped to job's requested vault policy and sends to Nomad Client. (Nomad server uses root or token role token, details here: https://www.nomadproject.io/docs/vault-integration/index.html#required-vault-policies)
2. Nomad client unwraps the wrapped token via Vault API.
3. Nomad client injects unwrapped auth token into task (env variable).
4. Task uses auth token to authenticate to Vault and read secrets.

# Steps

## Step 0: Configure Vault

If using the Vagrantfile, Vault and Nomad should already be integrated. Also, the Vault server's database secret backend is already configured to talk with the database. The code is listed here: https://github.com/hashicorp/nomad-guides/blob/master/provision/vagrant/vault_init_and_unseal.sh#L58

Setup a Vault policy for our application to use. This policy file allows our services in Nomad to read from Vault's MySQL database backend. Note: The quick setup vagrantfile stores the root token in Consul for ease of setup and playing around with these demos. This is NOT best practice. 
```bash
vagrant@node1:/vagrant/vault-examples/goapp$ cat golang_vault_setup.sh
#!/bin/bash

consul kv get service/vault/root-token | vault auth -

POLICY='path "database/creds/readonly" { capabilities = [ "read", "list" ] }'

echo $POLICY > policy-mysql.hcl

vault policy-write mysql policy-mysql.hcl
```
Execute the script:
```bash
vagrant@node1:/vagrant/vault-examples/goapp$ ./golang_vault_setup.sh
Successfully authenticated! You are now logged in.
token: 25bf4150-94a4-7292-974c-9c3fa4c8ee53
token_duration: 0
token_policies: [root]
Policy 'mysql' written.
```

## Step 1: Review the application.nomad job file
There are several important bits of this job file. 
First, We must specify the Vault stanza so Nomad creates a token with Vault for our tasks to authenticate. Nomad will automatically handle token renewal for us. A Nomad server will create a wrapped auth token for the MySQL policy, the nomad client unwraps it and injects the actual auth token into our tasks.

```bash
      vault {
        policies = [ "mysql" ]
      }
```
 
 
Second, our application will authenticate to Vault via that injected token and Vault's address. In this example, we leverage Consul for service discovery and can query it to find our other services (MySQL is also registered as a service in Consul).
From the job file:
```bash
      env {
        VAULT_ADDR = "http://active.vault.service.consul:8200"
        APP_DB_HOST = "db.service.consul:3306"
      }
```
We pass this information as an environment variable to our tasks in this job. Also, when using the Vault integration, another variable `VAULT_TOKEN` is injected. This info is discussed in more detail here: https://www.nomadproject.io/docs/job-specification/vault.html.

In our Golang code we can leverage these environment variables to talk with Vault for pulling our database credentials.

```bash
import (
    . . .
    "github.com/hashicorp/vault/api"  
)
func main() {
    . . .
    vaultToken := os.Getenv("VAULT_TOKEN")
    vaultAddr := os.Getenv("VAULT_ADDR")
    dbAddr := os.Getenv("APP_DB_HOST")
    . . .
    config := api.Config{Address: vaultAddr}
    client, err := api.NewClient(&config)
    client.SetToken(vaultToken)
    . . .
    secret, err := client.Logical().Read("database/creds/readonly")
}
```
## Step 2: Run the application.
```bash
vagrant@node1:/vagrant/vault-examples/goapp$ nomad run application.nomad
==> Monitoring evaluation "76b1d775"
    Evaluation triggered by job "app"
    Evaluation within deployment: "3e423222"
    Allocation "2d6db3e2" created: node "a79b11ff", group "app"
    Allocation "748b358f" created: node "34bec70a", group "app"
    Allocation "9112a050" created: node "c4b9b97e", group "app"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "76b1d775" finished with status "complete"

vagrant@node1:/vagrant/vault-examples/goapp$ nomad status app
. . .
. . .
Allocations
ID        Node ID   Task Group  Version  Desired  Status    Created At
280d05c8  4b2bd3e6  app         2        run      running   01/04/18 20:28:40 UTC
793b5ecb  5183f61b  app         2        run      running   01/04/18 20:28:40 UTC
d17855b9  e338c9d0  app         2        run      running   01/04/18 20:28:40 UTC
```
## Step 3: Validate dynamic credentials

Now, lets check the application logs to make sure they were able to receive dynamic credentials from Vault and authenticate to the database. Grab an allocation ID from the `nomad status app` command.

```bash
$ nomad logs -stderr 280d05c8
2018/01/04 20:28:49 Starting Go App
2018/01/04 20:28:49 Getting database credentials...
2018/01/04 20:28:49 username v-read-40xpu913r, password A1a-73r2ywpqx6wrqqts
2018/01/04 20:28:49 Initializing database connection pool...
2018/01/04 20:28:49 HTTP service listening on 10.0.2.15:8080
2018/01/04 20:28:49 Renewing credentials: database/creds/readonly/01730a17-5fcb-61d9-093b-c228c8b2502e
```

Vault created the `v-read-40xpu913r` user and assosciated password in MySQL. Each of these usernames and passwords has an assosciated short lived lease. At the end of the lease, Vault will revoke these credentials and delete them from the database (unless renewed). This feature gives operatores the ability to revoke credentials early if the system is compromised or a database password is exposed.

Lets verify the users in the database quickly. (If using the Vagrantfile, login to node3)

```bash
$ vagrant ssh node3
$ mysql -h 192.168.50.152 -u vaultadmin -pvaultadminpassword
MariaDB [(none)]> SELECT User FROM mysql.user;
+------------------+
| User             |
+------------------+
| v-read-40xpu913r |
| v-read-q5sr6rzrz |
| v-read-xr3v2yrsr |
| vaultadmin       |
| root             |
+------------------+
```
You should see the dynamic users created by Vault in the database.

## Step 4: Revoking Dynamic Credentials GUI
In this step we imagine that a secret has been compromised (password committed to github, lost sticky note, etc.).

Authenticate to the Vault GUI with admin credentials (Requires access to revoke auth and database tokens). If using the vagrantfile you can login using `username: vault` and `password: vault` or use the root token.

If using Vagrantfile: http://localhost:8200/ui/vault/auth

Once authenticated, go to the lease management page at top.
![](https://raw.githubusercontent.com/hashicorp/nomad-guides/master/assets/Vault_GUI_main.png)

![](https://raw.githubusercontent.com/hashicorp/nomad-guides/master/assets/Vault_GUI_leases.png)

Click on the MySQL leases tab

![](https://raw.githubusercontent.com/hashicorp/nomad-guides/master/assets/Vault_GUI_mysql.png)


Now click on `force revoke prefix` at the right. This forces Vault to delete the assosciated users and passwords from the database. Now all application database applications are invalid and will lose access. 

Check the database again, the dynamic users should be deleted.
```bash
MariaDB [(none)]> SELECT User FROM mysql.user;
+------------+
| User       |
+------------+
| vaultadmin |
| root       |
+------------+
```

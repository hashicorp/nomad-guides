#Nomad-Vault Nginx PKI

### TLDR;
```bash
vagrant@node1:/vagrant/vault-examples/nginx/PKI$ ./pki_vault_setup.sh

vagrant@node1:/vagrant/vault-examples/nginx/PKI$ nomad run nginx-pki-secret.nomad

#visit your browser (If using Vagrantfile)
https://localhost:9443/
```

## Estimated Time to Complete
20 minutes

## Prerequisites
A Nomad cluster should be up and running. Setup a cluster with OSS or enterprise binaries using the vagrantfile here: https://github.com/hashicorp/nomad-guides/tree/master/provision/vagrant

A Vault cluster must also be running and unsealed. The Vagrantfile above automatically installs/configufes/unseals Vault.

## Challenge
Internal PKI can be a very difficult challenge to scale and maintain. Because of this difficulty, many organizations will leave connections within their infrastrcuture unencrypted over HTTP.

## Solution
We can leverage Vault's dynamic PKI secret backend to automate the creation of internal PKI certs for our Nomad services. This greatly simplifies and automates our entire internal PKI infrastructure. More details here: https://www.vaultproject.io/docs/secrets/pki/index.html

# Steps

## Step 0: Review nginx-pki-secret.nomad job file
There are two important bits of the job file.

First, we specify a policy for this task to use (Nomad will generate a token and hand it to the task).
```bash
    vault {
      policies = ["superuser"]
    }
```

Second, this template block is used to pull secrets from Vault using the token from above.
```bash
      template {
        data = <<EOH
        {{ with secret "pki/issue/consul-service" "common_name=nginx.service.consul" "ttl=30m" }}
        {{ .Data.certificate }}
        {{ .Data.private_key }}
        {{ end }}
      EOH

        destination = "secret/cert.key"
      }
```
Nomad reads from the configured Vault pki secret backend path (pki/issue/consul-service) to generate a dynamic cert and key. Nomad then templates that information to the destination file within nginx container.

## Step 1: Configure Vault
We need to setup the Vault PKI backend and create a role for signing certs. We will also create a super user policy that Nomad will create a token for and pass to our tasks/template.

```bash
vagrant@node1:/vagrant/vault-examples/nginx/pki$ cat pki_vault_setup.sh
#!/bin/bash

consul kv get service/vault/root-token | vault auth -

vault mount pki

vault write pki/root/generate/internal \
	  common_name=service.consul

vault write pki/roles/consul-service \
    generate_lease=true \
    allowed_domains="service.consul" \
    allow_subdomains="true"

vault write pki/issue/consul-service \
    common_name=nginx.service.consul \
    ttl=2h

POLICY='path "*" { capabilities = ["create", "read", "update", "delete", "list", "sudo"] }'

echo $POLICY > policy-superuser.hcl

vault policy-write superuser policy-superuser.hcl
```

Execute the script
```bash
vagrant@node1:/vagrant/vault-examples/nginx/pki$ ./pki_vault_setup.sh
```

## Step 2: Run the Job
```bash
vagrant@node1:/vagrant/vault-examples/nginx/PKI$ nomad run nginx-pki-secret.nomad
```

## Step 3: Validate Results
The nginx containers should be running on port 443 of your Nomad clients (static port configuration)

If using the Vagrantfile go to your browswer at:
https://localhost:9443/

Your browswer should warn you of an untrusted cert. You can use the cert generated from the configuration script (pki_vault_setup.sh) for the root ca in your browser if you would like.

Once rendered, you should see a webpage showing the dynamic cert and key used by the Nginx task for its SSL config.

![](https://raw.githubusercontent.com/hashicorp/nomad-guides/master/assets/Nginx_PKI.png)


# Nomad-Vault integration
The goal of this guide is to help users configure Nomad to use Vault for deploying secrets into applications.

## Estimated Time to Complete
10 minutes

## Challenge
Many workloads require access to tokens, passwords, certificates, API keys, and other secrets. Deploying these initial secrets is a challenging problem known as 'secure introduction'.

Another key challenge is secret lifecycle management. If secrets are exposed or compromised, how do we stop the bleeding? Vault's dynamic secret backends generate secrets with short time to lives through leases. Those leases can also be manually revoked before their expiration in the event of a break glass scenario (exposure/compromise). In a database example, a revoked secret lease will cause Vault to delete the assosciated username/password from the database.

## Solution
To enable secure, auditable and easy access to your secrets, Nomad integrates with HashiCorp's Vault. Nomad servers and clients coordinate with Vault to derive a Vault token that has access to only the Vault policies the tasks need. Nomad clients make the token available to the task and handle the tokens renewal. Further, Nomad's template block can retrieve secrets from Vault making it easier than ever to secure your infrastructure.

In this Guide we will quickly walk through the configuratinon of Nomad and Vault to use this integration.

This explanation is covered in greater detail here: https://www.nomadproject.io/docs/vault-integration/index.html

# Steps
To see a more in depth explanation we highly recommend you read through the following example in the Hashicorp Nomad documentation.

1. Vault stanza in Nomad CONFIGURATION file: https://www.nomadproject.io/docs/agent/configuration/vault.html

2. Explanation of Vault integration: https://www.nomadproject.io/docs/vault-integration/index.html

3. Vault stanza in Nomad JOB file: https://www.nomadproject.io/docs/job-specification/vault.html

## Step 1:

Review setup code for the Nomad-Vault configuration code here: https://github.com/hashicorp/nomad-guides/blob/master/provision/vagrant/vault_nomad_integration.sh

## Step 2: nomad-server policy
Before we can use Nomad integrated with Vault we need to configure Vault properly. This entails a couple things.

First we need to create a policy for our Nomad Servers. This policy will allow the Nomad Servers to take actions like creating tokens against our "Token Role" that we will create in a subsequent step. Essentially we are giving Nomad the priviledge to create (allowed) tokens for tasks/containers that it launches.

The Entire workflow looks like this:
1. Nomad server asks for and receives wrapped token (from Vault) scoped to job's requested vault policy and sends to Nomad Client. (Nomad server uses token role)
2. Nomad client unwraps the wrapped token via Vault API.
3. Nomad client injects unwrapped auth token into task (env variable).
4. Task uses auth token to authenticate to Vault and read secrets.

So back to our code example. We need to do the following steps first. Explanations in code. We  assume you are logged into an active Vault server.
```
echo '
# Allow creating tokens under "nomad-cluster" token role. The token role name
# should be updated if "nomad-cluster" is not used.
path "auth/token/create/nomad-cluster" {
  capabilities = ["update"]
}
# Allow looking up "nomad-cluster" token role. The token role name should be
# updated if "nomad-cluster" is not used.
path "auth/token/roles/nomad-cluster" {
  capabilities = ["read"]
}
# Allow looking up the token passed to Nomad to validate # the token has the
# proper capabilities. This is provided by the "default" policy.
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
# Allow looking up incoming tokens to validate they have permissions to access
# the tokens they are requesting. This is only required if
# `allow_unauthenticated` is set to false.
path "auth/token/lookup" {
  capabilities = ["update"]
}
# Allow revoking tokens that should no longer exist. This allows revoking
# tokens for dead tasks.
path "auth/token/revoke-accessor" {
  capabilities = ["update"]
}
# Allow checking the capabilities of our own token. This is used to validate the
# token upon startup.
path "sys/capabilities-self" {
  capabilities = ["update"]
}
# Allow our own token to be renewed.
path "auth/token/renew-self" {
  capabilities = ["update"]
}' | vault policy-write nomad-server -
```
The last step writes this policy file to Vault with the name "nomad-server".

## Step 3: nomad-cluster Role
Now we need to create a "role" that our Nomad cluster will create tokens with.  Config options explained here: https://www.nomadproject.io/docs/vault-integration/index.html#vault-token-role-configuration

```
echo '
{
  "disallowed_policies": "nomad-server",
  "explicit_max_ttl": 0,
  "name": "nomad-cluster",
  "orphan": false,
  "period": 259200,
  "renewable": true
}' | vault write /auth/token/roles/nomad-cluster -
```

We end the command by writing the json to a Vault Token Role.

## Step 4: Create nomad-server token
In this next step we create a token for the nomad-server policy created in step 2. This token will be used in our Nomad configuration files.

```
vault token-create -policy nomad-server -period 72h -orphan
```

## Step 5: Nomad configuration files
Now on the Nomad servers (not needed for clients) we add the following stanza to our Nomad config files. Put your token from step 4 into the "token" config option.

```
vault {
  enabled = true
  create_from_role = "nomad-cluster"
  address = "http://active.vault.service.consul:8200"
  token = "$YOUR_TOKEN_FROM_STEP_4"
}
```

## Step 6: Restart Nomad Servers
Now restart the servers. You should see the following in the Nomad server logs.
```
Jan 09 15:26:00 node1 nomad[23058]:     2018/01/09 15:25:58.458592 [INFO] fingerprint.vault: Vault is available
Jan 09 15:26:00 node1 nomad[23058]:     2018/01/09 15:25:58.458875 [DEBUG] client: fingerprinting vault every 15s
```









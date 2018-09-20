vagrant@node1:~$ cd /vagrant/application-deployment/
vagrant@node1:/vagrant/application-deployment$ ls
fabio          go-vault-dynamic-mysql-creds  http-echo  nginx           nginx-vault-pki  redis
go-blue-green  haproxy                       jenkins    nginx-vault-kv  README.md# Vagrant: Nomad Cluster (Single Vault server on node3)
Spins up 3 virtual machines with Nomad installed as both Client and Server mode. Node3 also has Vault installed to show Nomad-Vault integration as well as MySQL server. WARNING: Nomad severs are configured with the root-token. A Nomad token role should be used in production as shown here: https://www.nomadproject.io/docs/vault-integration/index.html.

# Usage
(OPTIONAL) If you would like to use the enterprise binaries download and place the unzipped binaries in the root directory of nomad-guides

```bash
$ pwd
/Users/andrewklaas/hashicorp/nomad-guides
$ ls -l
application-deployment
consul #consul enterprise binary
multi-cloud
nomad #nomad enterprise binary
operations
provision
shared
vault #vault enterprise binary
workload-flexibility
```

1. Run `vagrant up`
```bash
$ vagrant up
. . . 
. . . Vagrant running . . .
. . .
==> node1:     Nomad has been provisioned and is available at the following web address:
==> node1:     http://localhost:4646/ui/     <<----  Primary Nomad UI (node1)
==> node1:     Nomad has Consul storage backend with web UI available at the following web address:
==> node1:     http://localhost:8500/ui/     <<----  Primary Consul UI (node1)
==> node1:     Primary Vault node has been provisioned and is available at the following web address:
==> node1:     http://localhost:8200/ui/     <<----  Primary Vault UI (node3)
==> node1:
==> node1:     Nomad node2 has been provisioned and is available at the following web address:
==> node1:     http://localhost:5646/ui/     <<----  Nomad UI (node2)
==> node1:     Nomad node3 has been provisioned and is available at the following web address:
==> node1:     http://localhost:6646/ui/     <<----  Nomad UI (node3)


```

2. Ssh into one of the nodes (Vault is running on Node3)
```bash
vagrant ssh node1
```


3. Check Nomad cluster health
```bash
vagrant@node1:~$ nomad server-members
Name          Address         Port  Status  Leader  Protocol  Build      Datacenter  Region
node1.global  192.168.50.150  4648  alive   false   2         0.7.0+ent  dc1         global
node2.global  192.168.50.151  4648  alive   false   2         0.7.0+ent  dc1         global
node3.global  192.168.50.152  4648  alive   true    2         0.7.0+ent  dc1         global
vagrant@node1:~$ nomad node-status
ID        DC   Name   Class   Drain  Status
5ba5d3c6  dc1  node2  <none>  false  ready
fb792a08  dc1  node3  <none>  false  ready
1a3bf4ca  dc1  node1  <none>  false  ready
```

4. If you want to use Vault from the CLI, Grab the root-token from Consul (NOT BEST PRACTICE: FOR DEMO USE ONLY)
```bash
vagrant@node1:~$ consul kv get service/vault/root-token
6389c4e7-9f0a-f5f2-9c71-d5cec294c99a

vagrant@node1:~$ export VAULT_TOKEN=6389c4e7-9f0a-f5f2-9c71-d5cec294c99a

vagrant@node1:~$ vault status
Type: shamir
Sealed: false
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0
Unseal Nonce:
Version: 0.9.0.1+ent
Cluster Name: vault-cluster-4a931870
Cluster ID: 955835ed-dc1d-004f-c4ee-4637384e21ff

High-Availability Enabled: true
	Mode: active
	Leader Cluster Address: https://192.168.50.152:8201

```

5. Change directory to "/vagrant/application-deployment" and start deploying jobs

```
vagrant@node1:~$ cd /vagrant/application-deployment/
vagrant@node1:/vagrant/application-deployment$ ls
fabio          go-vault-dynamic-mysql-creds  http-echo  nginx           nginx-vault-pki  redis
go-blue-green  haproxy                       jenkins    nginx-vault-kv  README.md
```
# Provision a Development Nomad Cluster in Vagrant

The goal of this guide is to allows users to easily provision a development Nomad cluster in just a few commands.

## Reference Material

- [Vagrant Getting Started](https://www.vagrantup.com/intro/getting-started/index.html)
- [Vagrant Docs](https://www.vagrantup.com/docs/index.html)
- [Nomad Getting Started](https://www.nomadproject.io/intro/getting-started/install.html)
- [Nomad Docs](https://www.nomadproject.io/docs/index.html)

## Estimated Time to Complete

5 minutes.

## Challenge

There are many different ways to provision and configure an easily accessible development Nomad cluster, making it difficult to get started.

## Solution

Provision a development Nomad cluster in Vagrant.

The Vagrant Development Nomad guide is for **educational purposes only**. It's designed to allow you to quickly standup a single instance with Nomad running in `-dev` mode. The single node is provisioned into a local VM, allowing for easy access to the instance. Because Nomad is running in `-dev` mode, all data is in-memory and not persisted to disk. If any agent fails or the node restarts, all data will be lost. This is only mean for local use.

## Prerequisites

- [Download Vagrant](https://www.vagrantup.com/downloads.html)
- [Download Virtualbox](https://www.virtualbox.org/wiki/Downloads)

## Steps

We will now provision the development Nomad cluster in Vagrant.

### Step 1 (OPTIONAL): Copy over enterprise binaries

If you want to override the OSS binaries with Enterprise ones, you can copy a Linux version of the enterprise binaries into the enterprise-binaries directory.   You are responsible for downloading and verifying validity of these binaries.   

DO NOT CHECK BINARIES INTO GIT!!!!
DO NOT CHECK BINARIES INTO GIT!!!!
DO NOT CHECK BINARIES INTO GIT!!!!

### Step 2: Start Vagrant

Run `vagrant up` to start the VM and configure Nomad. That's it! Once provisioned, view the Vagrant ouput for next steps.

#### CLI

[`vagrant up` Command](https://www.vagrantup.com/docs/cli/up.html)

##### Request

```sh
$ vagrant up
```

##### Response
```
```

## Next Steps

Now that you've provisioned and configured a development Nomad cluster, start walking through the [Nomad Guides](https://www.nomadproject.io/guides/index.html).

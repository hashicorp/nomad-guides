----
-	Website: https://www.nomadproject.io
-	GitHub repository: https://github.com/hashicorp/nomad
-	IRC: `#nomad-tool` on Freenode
-	Announcement list: [Google Groups](https://groups.google.com/group/hashicorp-announce)
-	Discussion list: [Google Groups](https://groups.google.com/group/nomad-tool)
-	Resources: https://www.nomadproject.io/resources.html

<img src="https://cdn.rawgit.com/hashicorp/nomad/master/website/source/assets/images/logo-text.svg" width="500" />

----

# Nomad-Guides
Example usage of HashiCorp Nomad (Work In Progress)

## provision
This area will contain instructions to provision Nomad and Consul as a first step to start using these tools.

These may include use cases installing Nomad in cloud services via Terraform, or within virtual environments using Vagrant, or running Nomad in a local development mode.

## application-deployment
This area will contain instructions and gudies for deploying applications on Nomad. This area contains examples and guides for deploying secrets (from Vault) into your Nomad applications.

## operations
This area will contain instructions for operating Nomad. This includes topics such as configuring Sentinel policies, namespaces, ACLs etc.

## `gitignore.tf` Files

You may notice some [`gitignore.tf`](operations/provision-consul/best-practices/terraform-aws/gitignore.tf) files in certain directories. `.tf` files that contain the word "gitignore" are ignored by git in the [`.gitignore`](./.gitignore) file.

If you have local Terraform configuration that you want ignored (like Terraform backend configuration), create a new file in the directory (separate from `gitignore.tf`) that contains the word "gitignore" (e.g. `backend.gitignore.tf`) and it won't be picked up as a change.

### Contributing
We welcome contributions and feedback!  For guide submissions, please see [the contributions guide](CONTRIBUTING.md)

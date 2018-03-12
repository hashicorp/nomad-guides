variable "name"         { }
variable "provider"     { default = "aws" }
variable "local_ip_url" { default = "http://169.254.169.254/latest/meta-data/local-ipv4" }
variable "ami_owner"    { default = "309956199498" } # Base RHEL owner
variable "ami_name"     { default = "*RHEL-7.3_HVM_GA-*" } # Base RHEL name

variable "consul_version"  { default = "0.9.2" }
variable "consul_url"      { default = "" }
variable "consul_image_id" { default = "" }

variable "nomad_version"  { default = "0.6.2" }
variable "nomad_url"      { default = "" }
variable "nomad_image_id" { default = "" }
variable "nomad_servers"  { default = "-1" }
variable "nomad_clients"  { default = "1" }

variable "network_tags" {
  type    = "map"
  default = { }
}

variable "consul_tags" {
  type    = "list"
  default = [ ]
}

variable "nomad_tags" {
  type    = "list"
  default = [ ]
}

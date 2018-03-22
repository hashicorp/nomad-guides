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

variable "consul_server_config"       { default = "" }
variable "consul_client_config"       { default = "" }
variable "nomad_server_config"        { default = "# No additional Nomad Server config" }
variable "nomad_server_stanza"        { default = "# No additional Nomad Server stanza config" }
variable "nomad_server_consul_stanza" { default = "# No additional Nomad Server Consul stanza config" }
variable "nomad_client_config"        { default = "# No additional Nomad Client config" }
variable "nomad_client_stanza"        { default = "# No additional Nomad Client stanza config" }
variable "nomad_client_consul_stanza" { default = "# No additional Nomad Client Consul stanza config" }

variable "install_docker"     { default = true }
variable "install_oracle_jdk" { default = false }

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

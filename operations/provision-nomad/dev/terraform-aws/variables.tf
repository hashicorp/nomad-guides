variable "name"              { }
variable "vpc_cidrs_public"  { type = "list" }
variable "vpc_cidrs_private" { type = "list" }
variable "nat_count"         { }
variable "bastion_count"     { }
variable "nomad_public_ip"   { }
variable "nomad_count"       { }
variable "ami_owner"         { default = "309956199498" } # Base RHEL owner
variable "ami_name"          { default = "*RHEL-7.3_HVM_GA-*" } # Base RHEL name
variable "nomad_version"     { default = "0.7.1" }
variable "nomad_url"         { default = "" }
variable "nomad_image_id"    { default = "" }

variable "install_docker"     { default = "true" }
variable "install_oracle_jdk" { default = "false" }

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

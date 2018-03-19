#!/bin/sh
yum -y install wget unzip
wget https://releases.hashicorp.com/nomad/0.7.1/nomad_0.7.1_linux_amd64.zip -O nomad.zip
unzip nomad.zip
mv nomad /usr/local/bin/nomad
chmod 755 /usr/local/bin/nomad
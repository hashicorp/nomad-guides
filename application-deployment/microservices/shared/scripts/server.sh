#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


set -e

CONFIGDIR=/ops/shared/config

CONSULCONFIGDIR=/etc/consul.d
NOMADCONFIGDIR=/etc/nomad.d
HOME_DIR=ubuntu

# Wait for network
sleep 15

IP_ADDRESS=$(curl http://instance-data/latest/meta-data/local-ipv4)
DOCKER_BRIDGE_IP_ADDRESS=(`ifconfig docker0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`)
SERVER_COUNT=$1
REGION=$2
CLUSTER_TAG_VALUE=$3
TOKEN_FOR_NOMAD=$4
VAULT_URL=$5

# Consul
sed -i "s/IP_ADDRESS/$IP_ADDRESS/g" $CONFIGDIR/consul.json
sed -i "s/SERVER_COUNT/$SERVER_COUNT/g" $CONFIGDIR/consul.json
sed -i "s/REGION/$REGION/g" $CONFIGDIR/consul_upstart.conf
sed -i "s/CLUSTER_TAG_VALUE/$CLUSTER_TAG_VALUE/g" $CONFIGDIR/consul_upstart.conf
cp $CONFIGDIR/consul.json $CONSULCONFIGDIR
cp $CONFIGDIR/consul_upstart.conf /etc/init/consul.conf

service consul start
sleep 10
export CONSUL_HTTP_ADDR=$IP_ADDRESS:8500

# Nomad
sed -i "s/IP_ADDRESS/$IP_ADDRESS/g" $CONFIGDIR/nomad.hcl
sed -i "s/SERVER_COUNT/$SERVER_COUNT/g" $CONFIGDIR/nomad.hcl
sed -i "s@VAULT_URL@$VAULT_URL@g" $CONFIGDIR/nomad.hcl
sed -i "s/TOKEN_FOR_NOMAD/$TOKEN_FOR_NOMAD/g" $CONFIGDIR/nomad.hcl
cp $CONFIGDIR/nomad.hcl $NOMADCONFIGDIR
cp $CONFIGDIR/nomad_upstart.conf /etc/init/nomad.conf
export NOMAD_ADDR=http://$IP_ADDRESS:4646

# Add hostname to /etc/hosts
echo "127.0.0.1 $(hostname)" | tee --append /etc/hosts

# Add Docker bridge network IP to /etc/resolv.conf (at the top)
#echo "nameserver $DOCKER_BRIDGE_IP_ADDRESS" | tee /etc/resolv.conf.new
echo "nameserver $IP_ADDRESS" | tee /etc/resolv.conf.new
cat /etc/resolv.conf | tee --append /etc/resolv.conf.new
mv /etc/resolv.conf.new /etc/resolv.conf

# Add search service.consul at bottom of /etc/resolv.conf
echo "search service.consul" | tee --append /etc/resolv.conf

# Set env vars for tool CLIs
echo "export CONSUL_HTTP_ADDR=$IP_ADDRESS:8500" | tee --append /home/$HOME_DIR/.bashrc
echo "export VAULT_ADDR=$VAULT_URL" | tee --append /home/$HOME_DIR/.bashrc
echo "export NOMAD_ADDR=http://$IP_ADDRESS:4646" | tee --append /home/$HOME_DIR/.bashrc

# Move daemon.json to /etc/docker
echo "{\"hosts\":[\"tcp://0.0.0.0:2375\",\"unix:///var/run/docker.sock\"],\"cluster-store\":\"consul://$IP_ADDRESS:8500\",\"cluster-advertise\":\"$IP_ADDRESS:2375\",\"dns\":[\"$IP_ADDRESS\"],\"dns-search\":[\"service.consul\"]}" > /home/ubuntu/daemon.json
mkdir -p /etc/docker
mv /home/ubuntu/daemon.json /etc/docker/daemon.json

# Start Docker
service docker restart

# Create Docker Networks
for network in sockshop; do
  if [ $(docker network ls | grep $network | wc -l) -eq 0 ]
  then
    docker network create -d overlay --attachable $network
  else
    echo docker network $network already created
  fi
done

# Copy Nomad jobs and scripts to desired locations
cp /ops/shared/jobs/*.nomad /home/ubuntu/.
chown -R $HOME_DIR:$HOME_DIR /home/$HOME_DIR/
chmod  666 /home/ubuntu/*

# Start Nomad
service nomad start
sleep 60

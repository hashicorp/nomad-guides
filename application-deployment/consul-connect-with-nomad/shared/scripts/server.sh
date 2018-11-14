#!/bin/bash

set -e

CONFIGDIR=/ops/shared/config

CONSULCONFIGDIR=/etc/consul.d
NOMADCONFIGDIR=/etc/nomad.d
HOME_DIR=ubuntu

# Wait for network
sleep 15

IP_ADDRESS=$(curl http://instance-data/latest/meta-data/local-ipv4)
SERVER_COUNT=$1
REGION=$2
CLUSTER_TAG_VALUE=$3

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
cp $CONFIGDIR/nomad.hcl $NOMADCONFIGDIR
cp $CONFIGDIR/nomad_upstart.conf /etc/init/nomad.conf
export NOMAD_ADDR=http://$IP_ADDRESS:4646

echo "nameserver $IP_ADDRESS" | tee /etc/resolv.conf.new
cat /etc/resolv.conf | tee --append /etc/resolv.conf.new
mv /etc/resolv.conf.new /etc/resolv.conf

# Add search service.consul at bottom of /etc/resolv.conf
echo "search service.consul" | tee --append /etc/resolv.conf

# Set env vars for tool CLIs
echo "export CONSUL_HTTP_ADDR=$IP_ADDRESS:8500" | tee --append /home/$HOME_DIR/.bashrc
echo "export NOMAD_ADDR=http://$IP_ADDRESS:4646" | tee --append /home/$HOME_DIR/.bashrc

# Start Docker
service docker restart

# Copy Nomad jobs and scripts to desired locations
cp /ops/shared/jobs/* /home/ubuntu/.
chown -R $HOME_DIR:$HOME_DIR /home/$HOME_DIR/
chmod  666 /home/ubuntu/*

# Start Nomad
service nomad start
sleep 60

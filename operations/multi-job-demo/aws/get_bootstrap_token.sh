#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


pk=$1
server_ip=$2
echo "${pk}" > private-key.pem
chmod 600 private-key.pem

while ! [ -f bootstrap.txt ];
do
  scp -o StrictHostKeyChecking=no -i private-key.pem  ubuntu@${server_ip}:~/bootstrap.txt bootstrap.txt
  sleep 5
done

bootstrap_token=$(sed -n 2,2p bootstrap.txt | cut -d '=' -f 2 | sed 's/ //')

echo "{\"bootstrap_token\": \"$bootstrap_token\"}"

#!/bin/bash
# Copyright IBM Corp. 2017, 2026


set -e

exec > >(sudo tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sudo bash /ops/shared/scripts/server.sh "${server_count}" "${region}" "${cluster_tag_value}"

#!/bin/bash

echo "[---Begin install-docker.sh---]"

if [ "${install_docker}" = true ]; then
  echo "Install Docker"
  curl https://raw.githubusercontent.com/hashicorp/guides-configuration/f-refactor/nomad/scripts/install-docker.sh | bash
else
  echo "Skip Docker install"
fi

echo "[---install-docker.sh Complete---]"

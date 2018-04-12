#!/bin/bash

echo "[---Begin install-java.sh---]"

if [ "${java_install}" == true ] || [ "${java_install}" == 1 ]; then
  echo "Install Java"
  curl https://raw.githubusercontent.com/hashicorp/guides-configuration/f-refactor/nomad/scripts/install-java.sh | bash
else
  echo "Skip Java install"
fi

echo "[---install-java.sh Complete---]"

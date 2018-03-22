#!/bin/bash

echo "[---Begin install-oracle-jdk.sh---]"

echo "install_oracle_jdk: ${install_oracle_jdk}"
echo ${install_oracle_jdk}

if [ "${install_oracle_jdk}" = true ]; then
  echo "Install Oracle JDK"
  curl https://raw.githubusercontent.com/hashicorp/guides-configuration/f-refactor/nomad/scripts/install-oracle-jdk.sh | bash
else
  echo "Skip Oracle JDK install"
fi

echo "[---install-oracle-jdk.sh Complete---]"

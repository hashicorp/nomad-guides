#!/bin/bash

echo "[---Begin install-nomad-systemd.sh---]"

echo "Wait for system to be ready"
sleep 10

echo "Run base script"
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/f-refactor/shared/scripts/base.sh | bash

echo "Install Nomad"
export VERSION=${nomad_version}
export URL=${nomad_url}
export USER=root
export GROUP=root
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/f-refactor/nomad/scripts/install-nomad.sh | bash

echo "Install Nomad Systemd"
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/f-refactor/nomad/scripts/install-nomad-systemd.sh | bash

echo "Cleanup install files"
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/f-refactor/shared/scripts/cleanup.sh | bash

echo "[---install-nomad-systemd.sh Complete---]"

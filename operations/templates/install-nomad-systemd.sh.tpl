#!/bin/bash

echo "[---Begin install-nomad-systemd.sh---]"

echo "Run base script"
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/f-refactor/shared/scripts/base.sh | bash

echo "Setup Nomad user"
export GROUP=nomad
export USER=nomad
export COMMENT=Nomad
export HOME=/srv/nomad
bash /tmp/shared/scripts/setup-user.sh

echo "Install Nomad"
export VERSION=${nomad_version}
export URL=${nomad_url}
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/f-refactor/nomad/scripts/install-nomad.sh | bash

echo "Install Nomad Systemd"
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/f-refactor/nomad/scripts/install-nomad-systemd.sh | bash

echo "Install Docker"
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/f-refactor/nomad/scripts/install-docker.sh | bash

echo "Install Oracle JDK"
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/f-refactor/nomad/scripts/install-oracle-jdk.sh | bash

echo "Cleanup install files"
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/f-refactor/shared/scripts/cleanup.sh | bash

echo "[---install-nomad-systemd.sh Complete---]"

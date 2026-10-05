#!/usr/bin/env bash
# Run inside a Kali VM. This installs packages; it does not start the test stack.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run: sudo bash install.sh' >&2; exit 1; }
source /etc/os-release
[[ $ID == kali ]] || { echo 'This installer is specifically for Kali Linux.' >&2; exit 1; }

packages=(ca-certificates curl openssl python3)
if ! docker compose version > /dev/null 2>&1; then
  # Keep an existing Docker CE installation; do not mix its packages with docker.io.
  for package in docker-ce docker-ce-cli containerd.io podman-docker; do
    if [[ $(dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null || true) == installed ]]; then
      echo "Found $package without a working 'docker compose' command." >&2
      echo 'Install Compose for that existing Docker installation, then rerun this script.' >&2
      exit 1
    fi
  done
  # Current Kali repositories supply Compose v2 through the docker-compose package.
  packages+=(docker.io docker-compose)
fi

apt-get update
apt-get install -y "${packages[@]}"
systemctl enable --now docker
docker compose version
docker info > /dev/null

# Cache the runtime for later experiments; no Node server is installed or started.
docker pull node:24-alpine
docker run --rm --network none node:24-alpine node --version
echo 'Kali dependencies installed. Next: sudo bash start.sh'


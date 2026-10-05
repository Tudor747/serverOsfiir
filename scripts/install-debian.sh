#!/usr/bin/env bash
# Run once on a fresh Debian 13 host. Review before running with sudo.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run with sudo on Debian 13.' >&2; exit 1; }
source /etc/os-release
[[ $ID == debian && $VERSION_ID == 13 ]] || { echo 'This installer targets Debian 13.' >&2; exit 1; }

# Avoid silently replacing another container installation.
for package in docker.io docker-compose docker-doc docker-buildx podman-docker containerd runc; do
  if [[ $(dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null || true) == installed ]]; then
    echo "Existing conflicting package: $package. Review Docker's migration instructions first." >&2
    exit 1
  fi
done

apt-get update
apt-get install -y ca-certificates curl git nano openssl python3 ufw openssh-server \
  unattended-upgrades certbot python3-certbot-dns-cloudflare

# Official Docker apt repository.
install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod 644 /etc/apt/keyrings/docker.asc
cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: trixie
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Official Tailscale apt repository, for private administration.
install -d -m 0755 /usr/share/keyrings
curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.noarmor.gpg \
  -o /usr/share/keyrings/tailscale-archive-keyring.gpg
curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.tailscale-keyring.list \
  -o /etc/apt/sources.list.d/tailscale.list
chmod 644 /usr/share/keyrings/tailscale-archive-keyring.gpg /etc/apt/sources.list.d/tailscale.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin tailscale
systemctl enable --now docker tailscaled ssh
docker pull node:24-alpine
docker run --rm --network none node:24-alpine node --version
echo 'Base packages installed. Continue with private SSH and firewall steps in docs/SETUP.md.'

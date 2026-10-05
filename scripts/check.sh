#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
probe_https
usage=$(df -P "$ROOT" | awk 'NR==2 {gsub(/%/, "", $5); print $5}')
(( usage < 85 )) || { echo "Disk usage is $usage%; investigate." >&2; exit 1; }
docker_usage=$(df -P /var/lib/docker | awk 'NR==2 {gsub(/%/, "", $5); print $5}')
(( docker_usage < 85 )) || { echo "Docker disk usage is $docker_usage%; investigate." >&2; exit 1; }
openssl x509 -checkend 604800 -noout -in state/letsencrypt/live/server/fullchain.pem
if [[ -n ${HEALTHCHECK_URL:-} ]]; then
  curl --fail --silent --show-error --max-time 15 "$HEALTHCHECK_URL" > /dev/null
fi
echo 'HTTPS, disk space and certificate checks passed.'

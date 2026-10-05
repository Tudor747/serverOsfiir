#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
docker info > /dev/null || { echo 'Docker must be running; use sudo bash start.sh.' >&2; exit 1; }
bash "$ROOT/make-cert.sh"
dc config --quiet
dc run --rm --no-deps nginx nginx -t
dc up -d --force-recreate nginx
bash "$ROOT/check.sh"
echo "Open https://localhost:$(https_port)/ in the browser INSIDE the Kali VM."


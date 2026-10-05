#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ -s state/letsencrypt/live/server/fullchain.pem && -s state/letsencrypt/live/server/privkey.pem ]] \
  || { echo 'Run: sudo bash scripts/tls.sh issue' >&2; exit 1; }
dc config --quiet
# Validate the rendered nginx configuration before changing the running service.
dc run --rm --no-deps nginx nginx -t
# Recreate so edits to the mounted template are rendered by the entrypoint.
dc up -d --force-recreate nginx
probe_https
echo 'HTTPS server started.'

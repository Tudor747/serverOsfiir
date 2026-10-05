#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
port=$(https_port)
curl --fail --silent --show-error --noproxy '*' \
  --retry 5 --retry-delay 2 --retry-all-errors --max-time 10 \
  --cacert "$ROOT/state/tls/server.crt" \
  --resolve "localhost:$port:127.0.0.1" "https://localhost:$port/healthz"
echo 'Local HTTPS check passed.'


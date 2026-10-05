#!/usr/bin/env bash
set -euo pipefail
umask 077
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
[[ -f .env ]] || { echo 'Copy .env.example to .env and edit it first.' >&2; exit 1; }

dc() {
  docker compose --project-directory "$ROOT" --env-file "$ROOT/.env" -f "$ROOT/compose.yaml" "$@"
}

domain() {
  dc config --format json | python3 -c 'import json,sys; print(json.load(sys.stdin)["services"]["nginx"]["environment"]["SERVER_DOMAIN"])'
}

probe_https() {
  local host
  host=$(domain)
  curl --fail --silent --show-error --noproxy '*' --max-time 10 \
    --retry 5 --retry-delay 2 --retry-all-errors \
    --resolve "$host:443:127.0.0.1" "https://$host/healthz"
}

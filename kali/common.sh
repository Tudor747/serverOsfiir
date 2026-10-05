#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$ROOT"
env_file="$ROOT/.env.example"
if [[ -f "$ROOT/.env" ]]; then env_file="$ROOT/.env"; fi

dc() {
  docker compose --project-directory "$ROOT" --env-file "$env_file" -f "$ROOT/compose.yaml" "$@"
}

https_port() {
  dc config --format json | python3 -c 'import json,sys; print(json.load(sys.stdin)["services"]["nginx"]["ports"][0]["published"])'
}


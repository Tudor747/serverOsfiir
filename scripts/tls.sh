#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ -s secrets/cloudflare.ini ]] || { echo 'Create secrets/cloudflare.ini first; see docs/SETUP.md.' >&2; exit 1; }
chmod 600 secrets/cloudflare.ini
mkdir -p state/letsencrypt state/certbot-work state/certbot-logs
args=(--config-dir "$ROOT/state/letsencrypt" --work-dir "$ROOT/state/certbot-work" --logs-dir "$ROOT/state/certbot-logs")
case ${1:-} in
  issue)
    config_json=$(dc config --format json)
    mapfile -t domains < <(printf '%s' "$config_json" | python3 -c 'import json,sys; e=json.load(sys.stdin)["services"]["nginx"]["environment"]; print(e["SERVER_DOMAIN"]); print(e.get("SECOND_DOMAIN", ""))')
    email=$(dc config --environment | sed -n 's/^LE_EMAIL=//p')
    [[ -n ${domains[0]:-} && -n $email ]] || { echo 'Set SERVER_DOMAIN and LE_EMAIL in .env.' >&2; exit 1; }
    names=(-d "${domains[0]}")
    if [[ -n ${domains[1]:-} ]]; then names+=(-d "${domains[1]}"); fi
    certbot certonly "${args[@]}" --non-interactive --agree-tos --email "$email" \
      --dns-cloudflare --dns-cloudflare-credentials "$ROOT/secrets/cloudflare.ini" \
      --dns-cloudflare-propagation-seconds 60 --cert-name server "${names[@]}"
    ;;
  renew)
    certbot renew "${args[@]}" --non-interactive
    dc exec -T nginx nginx -t
    dc exec -T nginx nginx -s reload
    ;;
  test) certbot renew "${args[@]}" --dry-run ;;
  *) echo 'Usage: tls.sh issue|renew|test' >&2; exit 1 ;;
esac

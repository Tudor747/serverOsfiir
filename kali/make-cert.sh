#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ $# -eq 0 || ( $# -eq 1 && $1 == --renew ) ]] || { echo 'Usage: make-cert.sh [--renew]' >&2; exit 1; }
umask 077
mkdir -p state/tls

if [[ ${1:-} != --renew && -s state/tls/server.crt && -s state/tls/server.key ]]; then
  openssl x509 -checkend 0 -noout -in state/tls/server.crt \
    || { echo 'Certificate expired. Run: sudo bash make-cert.sh --renew' >&2; exit 1; }
  echo 'Reusing the existing local certificate.'
  exit 0
fi

# A local certificate: no domain registration, ACME account or DNS token needed.
openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 365 \
  -keyout state/tls/server.key.new -out state/tls/server.crt.new \
  -subj '/CN=localhost' \
  -addext 'subjectAltName=DNS:localhost,DNS:kali.test,IP:127.0.0.1' \
  -addext 'extendedKeyUsage=serverAuth'
mv -- state/tls/server.key.new state/tls/server.key
mv -- state/tls/server.crt.new state/tls/server.crt
chmod 600 state/tls/server.key
echo 'Created a self-signed certificate for this VM.'


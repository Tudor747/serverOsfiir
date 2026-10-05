#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ $EUID -eq 0 && $ROOT == /opt/dorm-server ]] || { echo 'Run as root from /opt/dorm-server (or edit unit paths).' >&2; exit 1; }
install -m 644 systemd/dorm-tls.service systemd/dorm-tls.timer \
  systemd/dorm-check.service systemd/dorm-check.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now dorm-tls.timer dorm-check.timer
systemctl list-timers 'dorm-*'

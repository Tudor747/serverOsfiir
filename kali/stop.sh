#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
dc down
echo 'Test container stopped and removed. Local certificates and Docker images were kept.'


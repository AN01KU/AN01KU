#!/usr/bin/env bash
# Regenerate README.md from a local shared-config checkout.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED_CONFIG="${SHARED_CONFIG_DIR:-${ROOT}/../shared-config}"

bash "${ROOT}/scripts/build-readme.sh" "$SHARED_CONFIG"

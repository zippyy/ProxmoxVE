#!/usr/bin/env bash

# Plane Community Edition installer (historical native installer).
# Kept at its original name; the separate Commercial Edition installer is:
# install/plane-commercial-install.sh
#
# This immutable commit is the original native Community installer preserved
# in this repository before the Commercial installer was added.

set -euo pipefail

ORIGINAL_COMMIT="87f2189cbb5b73c9c2204a292fd06efa465b0824"
ORIGINAL_URL="https://raw.githubusercontent.com/zippyy/ProxmoxVE/${ORIGINAL_COMMIT}/install/plane-install.sh"
TMP_SCRIPT=$(mktemp)
trap 'rm -f "$TMP_SCRIPT"' EXIT

curl -fsSL --retry 3 --retry-delay 2 "$ORIGINAL_URL" -o "$TMP_SCRIPT"
exec bash "$TMP_SCRIPT"

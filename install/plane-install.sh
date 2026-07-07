#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: onionrings29
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://plane.so
#
# This installs Plane Commercial Edition through Plane's supported Prime CLI.
# Plane Commercial is a separate, closed-source Docker deployment; do not
# replace this with the Community Edition source build.

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

if [[ -d /opt/plane/apps || -e /opt/plane/data || -x /usr/local/bin/prime-cli ]] || command -v prime-cli >/dev/null 2>&1; then
  echo ""
  echo "An existing Plane installation was detected."
  echo "Plane requires Commercial Edition to be installed on a fresh machine."
  echo "Back up the Community instance, deploy this installer in a new LXC, then"
  echo "restore the database and uploads using Plane's documented migration path."
  exit 1
fi

if [[ -f /proc/1/environ ]] && tr '\0' '\n' </proc/1/environ | grep -qx 'container=lxc'; then
  echo ""
  echo "Plane Commercial runs in Docker. Before continuing, make sure this Proxmox"
  echo "LXC has nesting=1 and keyctl=1 enabled in Options > Features."
  echo ""
fi

msg_info "Installing prerequisites"
$STD apt-get install -y ca-certificates curl
msg_ok "Installed prerequisites"

msg_info "Downloading the official Plane Commercial installer"
INSTALLER=$(mktemp)
trap 'rm -f "$INSTALLER"' EXIT
if ! curl -fsSL --retry 3 --retry-delay 2 https://prime.plane.so/install/ -o "$INSTALLER"; then
  echo "Unable to download Plane's official Commercial Edition installer."
  exit 1
fi
chmod 700 "$INSTALLER"
msg_ok "Downloaded official installer"

echo ""
echo "Plane Commercial setup is interactive."
echo "Enter your public Plane domain when prompted, then choose Express unless"
echo "you need external PostgreSQL, Redis, or object storage."
echo ""

msg_info "Installing Plane Commercial Edition"
if ! sh "$INSTALLER"; then
  echo "Plane Commercial installation did not complete."
  echo "Check Docker with: systemctl status docker --no-pager"
  echo "Then rerun the installer after correcting the reported error."
  exit 1
fi
msg_ok "Installed Plane Commercial Edition"

if command -v prime-cli >/dev/null 2>&1; then
  msg_info "Checking Plane health"
  prime-cli healthcheck || true
  msg_ok "Plane Commercial installation completed"
fi

cat <<'EOF' >/root/plane-commercial-notes.txt
Plane Commercial Edition was installed with Plane's Prime CLI.

Management:
  prime-cli monitor
  prime-cli healthcheck
  prime-cli restart
  prime-cli configure
  prime-cli upgrade

For an external reverse proxy, set free listener ports and SITE_ADDRESS=:80 in
Plane's plane.env, restart with `prime-cli restart`, then proxy the public
hostname to the configured Plane HTTP listener while preserving Host,
X-Forwarded-Host, X-Forwarded-Proto, X-Forwarded-For, and WebSocket headers.

Activate a Pro or Business subscription later in:
  Workspace Settings > Billing and plans
EOF

motd_ssh
customize
cleanup_lxc

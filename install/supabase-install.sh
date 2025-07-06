#!/usr/bin/env bash
# Copyright (c) 2021-2025 tteck
# Author: Brandon Anubis
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://supabase.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl gnupg ca-certificates lsb-release
msg_ok "Installed Dependencies"

msg_info "Installing Docker Engine & Compose"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo $ID)/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/$(. /etc/os-release && echo $ID) \
  $(lsb_release -cs) stable" >/etc/apt/sources.list.d/docker.list
$STD apt-get update
$STD apt-get install -y docker-ce docker-ce-cli containerd.io \
                       docker-buildx-plugin docker-compose-plugin
msg_ok "Installed Docker"

msg_info "Fetching Supabase compose (June 2025 tag)"
mkdir -p /opt/supabase/volumes/{db,storage,pooler,functions,logs}
curl -fsSL \
  https://raw.githubusercontent.com/supabase/supabase/2025.06/docker/docker-compose.yml \
  -o /opt/supabase/docker-compose.yml
msg_ok "Fetched compose"

msg_info "Creating environment file"
cat >/opt/supabase/.env <<EOF
POSTGRES_PASSWORD=$(openssl rand -hex 16)
JWT_SECRET=$(openssl rand -hex 32)
ANON_KEY=$(openssl rand -hex 16)
SERVICE_ROLE_KEY=$(openssl rand -hex 16)

SITE_URL=http://localhost
SUPABASE_PUBLIC_URL=http://localhost
API_EXTERNAL_URL=http://localhost

KONG_HTTP_PORT=8000
KONG_HTTPS_PORT=8443
POSTGRES_PORT=5432
POOLER_PROXY_PORT_TRANSACTION=6543
EOF
msg_ok "Created .env"

msg_info "Launching Supabase stack (grab a coffee)"
docker compose -p supabase \
  -f /opt/supabase/docker-compose.yml \
  --env-file /opt/supabase/.env up -d
msg_ok "Supabase stack is live"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

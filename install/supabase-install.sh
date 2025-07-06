#!/usr/bin/env bash
# Runs *inside* the new LXC
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"  # re-import helpers

color; verb_ip6; catch_errors
setting_up_container
network_check
update_os

# ---- Docker Engine & Compose v2 ------------------------------------------
msg_info "Installing Docker Engine"
apt-get update -qq
apt-get install -y curl gnupg ca-certificates lsb-release
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo $ID)/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/$(. /etc/os-release && echo $ID) \
  $(lsb_release -cs) stable" >/etc/apt/sources.list.d/docker.list
apt-get update -qq
apt-get install -y docker-ce docker-ce-cli containerd.io \
                   docker-buildx-plugin docker-compose-plugin
msg_ok "Docker installed"

# ---- Supabase stack -------------------------------------------------------
msg_info "Fetching Supabase compose (June 2025 tag)"
mkdir -p /opt/supabase/volumes/{db,storage,pooler,functions,logs}
curl -fsSL \
  https://raw.githubusercontent.com/supabase/supabase/2025.06/docker/docker-compose.yml \
  -o /opt/supabase/docker-compose.yml

# ---- .env with randomised secrets ----------------------------------------
msg_info "Creating .env"
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
msg_ok ".env ready"

# ---- bring everything online ---------------------------------------------
msg_info "Launching Supabase stack (grab a ☕)"
docker compose -p supabase \
  -f /opt/supabase/docker-compose.yml \
  --env-file /opt/supabase/.env up -d
msg_ok "Supabase is live"

motd_ssh
customize
cleanup
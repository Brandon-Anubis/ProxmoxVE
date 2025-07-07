#!/usr/bin/env bash

# --- Function Sourcing ---
if [[ -n "${FUNCTIONS_FILE_PATH:-}" ]]; then
    source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
else
    source <(curl -fsSL https://raw.githubusercontent.com/Brandon-Anubis/ProxmoxVE/main/misc/build.func)
fi

# Copyright (c) 2021-2025 tteck
# Author: Brandon Anubis
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://supabase.com/

APP="Supabase"

# ----------------------  defaults  ----------------------------------------
var_tags="${var_tags:-docker}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-30}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"
var_hostname="${var_hostname:-supabase}"
var_bridge="${var_bridge:-vmbr0}"
var_ip="${var_ip:-}"
var_install="${var_install:-supabase-install.sh}"

# ----------------------  framework bootstrap (correct order!) -------------
header_info "$APP"
variables
color
catch_errors

# --------------------- update-only hook -----------------------------------
update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/supabase ]]; then
        msg_error "No ${APP} installation found!"
        exit 1
    fi
    msg_info "Pulling latest ${APP} images"
    if ! docker compose -p supabase -f /opt/supabase/docker-compose.yml --env-file /opt/supabase/.env pull; then
        msg_error "Failed to pull images"
        exit 1
    fi
    msg_info "Re-creating containers"
    if ! docker compose -p supabase -f /opt/supabase/docker-compose.yml --env-file /opt/supabase/.env up -d; then
        msg_error "Failed to re-create containers"
        exit 1
    fi
    msg_ok "Updated ${APP} LXC"
    exit 0
}

# --------------------- build sequence -------------------------------------
start
build_container
description

msg_ok "Completed Successfully!\n"
IP=$(hostname -I | awk '{print $1}')
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it via:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP:-<CT-IP>}:8000${CL}"

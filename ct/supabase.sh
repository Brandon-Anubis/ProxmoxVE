#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
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
variables            # ← this was missing; sets RANDOM_UUID, prints defaults
color
catch_errors

# ---------- optional ADVANCED wizard --------------------------------------
function advanced_settings() {
  header_info "$APP — Advanced Setup"
  echo -e "${YW}Press Enter to accept the [default] shown in brackets.${CL}\n"

  read -r -p "Container ID     [next free] : " input && [[ -n $input ]] && var_ctid="$input"
  read -r -p "Hostname         [${var_hostname}] : " input && [[ -n $input ]] && var_hostname="$input"
  read -r -p "Bridge           [${var_bridge}] : "  input && [[ -n $input ]] && var_bridge="$input"
  read -r -p "Static IP/CIDR   [DHCP] : "          input && [[ -n $input ]] && var_ip="$input"
  read -r -p "CPU cores        [${var_cpu}] : "     input && [[ -n $input ]] && var_cpu="$input"
  read -r -p "RAM MiB          [${var_ram}] : "     input && [[ -n $input ]] && var_ram="$input"
  read -r -p "Disk GB          [${var_disk}] : "    input && [[ -n $input ]] && var_disk="$input"
  read -r -p "Privileged CT?   (y/N) : "            input && [[ ${input,,} == y ]] && var_unprivileged=0
  read -r -p "Custom tag list  [${var_tags}] : "    input && [[ -n $input ]] && var_tags="$input"
}

if [[ -t 0 ]]; then
  read -n1 -rp $'\nPress (a)dvanced setup  or  (Enter) to continue with defaults: ' key
  echo
  [[ ${key,,} == a ]] && advanced_settings
fi

variables                              # ← prints the final values to the user

# --------------------- update-only hook -----------------------------------
function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/supabase ]]; then
    msg_error "No ${APP} installation found!"
    exit
  fi
  msg_info "Pulling latest ${APP} images"
  docker compose -p supabase                                \
       -f /opt/supabase/docker-compose.yml                  \
       --env-file /opt/supabase/.env pull
  msg_info "Re-creating containers"
  docker compose -p supabase                                \
       -f /opt/supabase/docker-compose.yml                  \
       --env-file /opt/supabase/.env up -d
  msg_ok "Updated ${APP} LXC"
  exit
}

# --------------------- build sequence (must be three lines) ---------------
start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it via:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://<CT-IP>:8000${CL}"

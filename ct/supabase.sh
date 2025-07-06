#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/Brandon-Anubis/ProxmoxVE/main/misc/build.func)
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
advanced_settings() {
  header_info "$APP — Advanced Setup"
  echo -e "${YW}Press Enter to accept the [default] shown in brackets.${CL}\n"

  read -r -p "Container ID     [next free] : " input
  if [[ -n "$input" ]]; then var_ctid="$input"; fi

  read -r -p "Hostname         [${var_hostname}] : " input
  if [[ -n "$input" ]]; then var_hostname="$input"; fi

  read -r -p "Bridge           [${var_bridge}] : " input
  if [[ -n "$input" ]]; then var_bridge="$input"; fi

  read -r -p "Static IP/CIDR   [DHCP] : " input
  if [[ -n "$input" ]]; then var_ip="$input"; fi

  read -r -p "CPU cores        [${var_cpu}] : " input
  if [[ -n "$input" ]]; then var_cpu="$input"; fi

  read -r -p "RAM MiB          [${var_ram}] : " input
  if [[ -n "$input" ]]; then var_ram="$input"; fi

  read -r -p "Disk GB          [${var_disk}] : " input
  if [[ -n "$input" ]]; then var_disk="$input"; fi

  echo -e "${YW}Privileged containers have less isolation and are not recommended unless needed.${CL}"
  read -r -p "Privileged CT?   (y/N) : " input
  if [[ "${input,,}" == "y" ]]; then var_unprivileged=0; fi

  read -r -p "Custom tag list  [${var_tags}] : " input
  if [[ -n "$input" ]]; then var_tags="$input"; fi
}

if [[ -t 0 ]]; then
  read -n1 -rp $'\nPress (a)dvanced setup or (Enter) to continue with defaults: ' key
  echo
  if [[ "${key,,}" == "a" ]]; then
    advanced_settings
  fi
fi

variables

# --------------------- update-only hook -----------------------------------
function update_script() {
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

# --------------------- build sequence (must be three lines) ---------------
start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it via:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://<CT-IP>:8000${CL}"

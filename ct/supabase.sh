#!/usr/bin/env bash
# Supabase – Helper-Script (host side) for Proxmox VE
# Maintainer: Brandon Anubis
# License: MIT

APP="Supabase"

# ----------------------  defaults  ----------------------------------------
var_tags="${var_tags:-docker}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"     # MiB
var_disk="${var_disk:-30}"     # GB
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-1}"
var_hostname="${var_hostname:-supabase}"
var_bridge="${var_bridge:-vmbr0}"
var_ip="${var_ip:-}"           # blank -> DHCP
var_install="${var_install:-supabase-install.sh}"   # <─ NEW

# ----------------------  import helpers  ----------------------------------
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

header_info "$APP"
variables; color; catch_errors

# ----------------------  wizard  ------------------------------------------
function advanced_settings() {
  header_info "$APP — Advanced Setup"
  echo -e "${YW}Press Enter to accept the [default] shown in brackets.${CL}\n"

  read -r -p "Container ID     [next free] : " input
  if [[ -n "$input" ]];    then var_ctid="$input"; fi

  read -r -p "Hostname         [${var_hostname}] : " input
  if [[ -n "$input" ]];    then var_hostname="$input"; fi

  read -r -p "Bridge           [${var_bridge}] : "  input
  if [[ -n "$input" ]];    then var_bridge="$input"; fi

  read -r -p "Static IP/CIDR   [DHCP] : "          input
  if [[ -n "$input" ]];    then var_ip="$input"; fi

  read -r -p "CPU cores        [${var_cpu}] : "     input
  if [[ -n "$input" ]];    then var_cpu="$input"; fi

  read -r -p "RAM MiB          [${var_ram}] : "     input
  if [[ -n "$input" ]];    then var_ram="$input"; fi

  read -r -p "Disk GB          [${var_disk}] : "    input
  if [[ -n "$input" ]];    then var_disk="$input"; fi

  read -r -p "Privileged CT?   (y/N) : "            input
  if [[ "${input,,}" == "y" ]]; then var_unprivileged=0; fi

  read -r -p "Custom tag list  [${var_tags}] : "    input
  if [[ -n "$input" ]];    then var_tags="$input"; fi
}

if [[ -t 0 && ! "${ADVANCED,,}" == "y" ]]; then
  read -n1 -rp $'\nPress (a)dvanced setup  or  (Enter) to continue with defaults: ' key
  echo
  [[ ${key,,} == "a" ]] && ADVANCED=y
fi
[[ "${ADVANCED,,}" == "y" ]] && advanced_settings

# ----------------------  update-only path  --------------------------------
function update_script() {
  header_info
  check_container_storage
  check_container_resources
  [[ -d /opt/supabase ]] || { msg_error "No Supabase installation found!"; exit 1; }

  msg_info "Pulling latest Supabase images"
  docker compose -p supabase \
    -f /opt/supabase/docker-compose.yml \
    --env-file /opt/supabase/.env pull

  msg_info "Recreating containers"
  docker compose -p supabase \
    -f /opt/supabase/docker-compose.yml \
    --env-file /opt/supabase/.env up -d

  msg_ok "Supabase stack updated"
  exit
}

# ----------------------  build sequence  ----------------------------------
start
build_container
description

msg_ok "Supabase LXC created successfully!"
echo -e "${TAB}${INFO}${YW}Tip:${CL} reverse-proxy via your NPM-Plus CT:"
echo -e "${TAB}${TAB}➜  api.example.tld  →  http://<CT-IP>:8000"
